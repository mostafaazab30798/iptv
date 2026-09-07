/**
 * Hope TV — native <video> VOD helper for iOS Safari / AVPlayer.
 *
 * HTML5/AVPlayer cannot demux Matroska (.mkv). This module remuxes remote
 * MKV/AVI (via HTTP Range) into fragmented MP4 and feeds it to the same
 * <video> element through MediaSource / ManagedMediaSource so AVPlayer still
 * does hardware decode.
 */
(function () {
  'use strict';

  const MEDIABUNNY_URL = 'https://esm.sh/mediabunny@1.55.7';
  const MEDIABUNNY_AC3_URL = 'https://esm.sh/@mediabunny/ac3@1.55.7';

  // These codecs can be copied into MP4 without decoding/re-encoding. The
  // final MediaSource.isTypeSupported check below remains authoritative for
  // the particular iPhone/iPad and Safari version.
  const PASSTHROUGH_VIDEO = new Set(['avc', 'hevc', 'vp9', 'av1']);
  const PASSTHROUGH_AUDIO = new Set(['aac', 'mp3', 'opus', 'ac3', 'eac3']);
  const BUFFER_AHEAD_HIGH_SEC = 30;
  const BUFFER_BEHIND_KEEP_SEC = 10;
  const MAX_QUOTA_RETRIES = 8;

  /** @type {WeakMap<HTMLVideoElement, { cancel: () => Promise<void>, seek?: (time: number) => Promise<void>, revoke?: () => void }>} */
  const sessions = new WeakMap();

  let mediabunnyPromise = null;

  function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  function waitForUpdateEnd(sb) {
    return new Promise((resolve, reject) => {
      const onDone = () => {
        cleanup();
        resolve();
      };
      const onFail = () => {
        cleanup();
        reject(new Error('SourceBuffer error'));
      };
      const cleanup = () => {
        sb.removeEventListener('updateend', onDone);
        sb.removeEventListener('error', onFail);
      };
      sb.addEventListener('updateend', onDone, { once: true });
      sb.addEventListener('error', onFail, { once: true });
    });
  }

  function bufferedAheadOf(sb, t) {
    const ranges = sb.buffered;
    for (let i = 0; i < ranges.length; i++) {
      if (t >= ranges.start(i) - 0.5 && t <= ranges.end(i) + 0.5) {
        return ranges.end(i) - t;
      }
    }
    return 0;
  }

  function isBufferedAt(sb, time) {
    const ranges = sb.buffered;
    for (let i = 0; i < ranges.length; i++) {
      if (time >= ranges.start(i) - 0.25 && time <= ranges.end(i) + 0.25) {
        return true;
      }
    }
    return false;
  }

  async function loadMediabunny() {
    if (!mediabunnyPromise) {
      mediabunnyPromise = Promise.all([
        import(/* webpackIgnore: true */ MEDIABUNNY_URL),
        import(/* webpackIgnore: true */ MEDIABUNNY_AC3_URL).catch(() => null),
      ]).then(([mb, ac3]) => {
        if (ac3 && typeof ac3.registerAc3Decoder === 'function') {
          ac3.registerAc3Decoder();
        }
        return mb;
      });
    }
    return mediabunnyPromise;
  }

  async function probeContentType(url) {
    try {
      const res = await fetch(url, {
        method: 'GET',
        headers: { Range: 'bytes=0-15' },
      });
      const ct = (res.headers.get('content-type') || '').toLowerCase();
      const buf = new Uint8Array(await res.arrayBuffer());
      // EBML / Matroska magic
      const isMkv =
        buf.length >= 4 &&
        buf[0] === 0x1a &&
        buf[1] === 0x45 &&
        buf[2] === 0xdf &&
        buf[3] === 0xa3;
      // ISO BMFF ftyp
      const isMp4 =
        buf.length >= 8 &&
        buf[4] === 0x66 &&
        buf[5] === 0x74 &&
        buf[6] === 0x79 &&
        buf[7] === 0x70;
      const isHls =
        ct.includes('mpegurl') ||
        (buf.length >= 7 &&
          String.fromCharCode(...buf.subarray(0, 7)).toUpperCase() === '#EXTM3U');
      return { ct, isMkv, isMp4, isHls, ok: res.ok || res.status === 206 };
    } catch (_) {
      return { ct: '', isMkv: false, isMp4: false, isHls: false, ok: false };
    }
  }

  function deriveHlsCandidate(url) {
    const replaceExtension = (value) => {
      try {
        const parsed = new URL(value, window.location.href);
        if (!/\.[^/.]+$/i.test(parsed.pathname)) return value;
        parsed.pathname = parsed.pathname.replace(/\.[^/.]+$/i, '.m3u8');
        return parsed.toString();
      } catch (_) {
        return String(value).replace(/\.[^/?]+(?=\?|$)/i, '.m3u8');
      }
    };

    try {
      const outer = new URL(url, window.location.href);
      const target = outer.searchParams.get('url');
      if (target) {
        const hlsTarget = replaceExtension(target);
        if (hlsTarget === target) return null;
        outer.searchParams.set('url', hlsTarget);
        return outer.toString();
      }
      const candidate = replaceExtension(outer.toString());
      return candidate === outer.toString() ? null : candidate;
    } catch (_) {
      return null;
    }
  }

  async function playDirect(videoEl, url, startTime, mode) {
    videoEl.src = url;
    videoEl.load();
    if (startTime > 0) {
      videoEl.addEventListener(
        'loadedmetadata',
        () => {
          const duration = Number.isFinite(videoEl.duration) ? videoEl.duration : startTime;
          videoEl.currentTime = Math.min(startTime, Math.max(0, duration - 0.05));
        },
        { once: true }
      );
    }
    try {
      await videoEl.play();
    } catch (_) {}
    return { mode };
  }

  function getMediaSourceClass() {
    return window.ManagedMediaSource || window.MediaSource || null;
  }

  async function stop(videoEl) {
    const session = sessions.get(videoEl);
    if (session) {
      sessions.delete(videoEl);
      try {
        await session.cancel();
      } catch (_) {}
      try {
        session.revoke?.();
      } catch (_) {}
    }
    try {
      videoEl.pause();
      videoEl.removeAttribute('src');
      videoEl.srcObject = null;
      videoEl.load();
    } catch (_) {}
  }

  /**
   * @param {HTMLVideoElement} videoEl
   * @param {string} url same-origin /proxy URL
   * @param {number} startTime requested position in seconds
   * @returns {Promise<{ mode: string }>}
   */
  async function play(videoEl, url, startTime = 0) {
    await stop(videoEl);

    startTime = Math.max(0, Number(startTime) || 0);

    const probe = await probeContentType(url);
    // Native HLS and true MP4 go straight to AVPlayer.
    if (probe.isHls) {
      return playDirect(videoEl, url, startTime, 'direct-hls');
    }
    if (probe.isMp4 || (probe.ct.includes('mp4') && !probe.isMkv)) {
      return playDirect(videoEl, url, startTime, 'direct-mp4');
    }

    // Some IPTV panels expose a native VOD HLS representation next to the
    // advertised MKV/AVI URL. Prefer it when present: this gives iOS AVPlayer
    // server-authored segments and its most reliable random access path.
    const hlsCandidate = deriveHlsCandidate(url);
    if (hlsCandidate && hlsCandidate !== url) {
      const hlsProbe = await probeContentType(hlsCandidate);
      if (hlsProbe.ok && hlsProbe.isHls) {
        return playDirect(videoEl, hlsCandidate, startTime, 'companion-hls');
      }
    }

    return startRemux(videoEl, url, startTime, true);
  }

  /**
   * Builds a seekable MSE session. A fragmented MP4 stream is append-only, so
   * an out-of-buffer seek starts a fresh packet-copy remux at the closest
   * verified video keyframe. No codec conversion is performed on the device.
   */
  async function startRemux(videoEl, url, startTime, autoplay) {
    startTime = Math.max(0, Number(startTime) || 0);

    const MediaSourceClass = getMediaSourceClass();
    if (!MediaSourceClass) {
      throw new Error('MediaSource is not available in this browser');
    }

    const mb = await loadMediabunny();
    const {
      Input,
      Output,
      UrlSource,
      ALL_FORMATS,
      Mp4OutputFormat,
      StreamTarget,
      AppendOnlyStreamTarget,
      EncodedPacketSink,
      EncodedVideoPacketSource,
      EncodedAudioPacketSource,
    } = mb;

    const input = new Input({
      source: new UrlSource(url, { maxCacheSize: 16 * 1024 * 1024, parallelism: 2 }),
      formats: ALL_FORMATS,
    });

    const videoTrack = await input.getPrimaryVideoTrack();
    const videoCodec = videoTrack ? await videoTrack.getCodec() : null;
    if (!(videoTrack && videoCodec && PASSTHROUGH_VIDEO.has(videoCodec))) {
      await input.dispose?.();
      throw new Error(
        `The source video codec (${videoCodec || 'unknown'}) cannot be copied to Safari MP4`
      );
    }

    const videoCodecString = await videoTrack.getCodecParameterString();
    const videoDecoderConfig = await videoTrack.getDecoderConfig();
    if (!videoCodecString || !videoDecoderConfig) {
      await input.dispose?.();
      throw new Error('The source video track has no usable decoder configuration');
    }

    const audioTrack = await input.getPrimaryAudioTrack();
    const audioCodec = audioTrack ? await audioTrack.getCodec() : null;
    let audioCodecString = null;
    let audioDecoderConfig = null;
    if (audioTrack) {
      if (!(audioCodec && PASSTHROUGH_AUDIO.has(audioCodec))) {
        await input.dispose?.();
        throw new Error(
          `The source audio codec (${audioCodec || 'unknown'}) cannot be copied to Safari MP4`
        );
      }
      audioCodecString = await audioTrack.getCodecParameterString();
      audioDecoderConfig = await audioTrack.getDecoderConfig();
      if (!audioCodecString || !audioDecoderConfig) {
        await input.dispose?.();
        throw new Error('The source audio track has no usable decoder configuration');
      }
    }

    const codecList = audioCodecString
      ? `${videoCodecString}, ${audioCodecString}`
      : videoCodecString;
    const mimeType = `video/mp4; codecs="${codecList}"`;
    if (
      typeof MediaSourceClass.isTypeSupported === 'function' &&
      !MediaSourceClass.isTypeSupported(mimeType)
    ) {
      await input.dispose?.();
      throw new Error(`Unsupported MSE mime: ${mimeType}`);
    }

    const videoSink = new EncodedPacketSink(videoTrack);
    const requestedVideoPacket =
      startTime > 0
        ? await videoSink.getKeyPacket(startTime, { verifyKeyPackets: true })
        : await videoSink.getFirstKeyPacket({ verifyKeyPackets: true });
    const firstVideoPacket =
      requestedVideoPacket ||
      (await videoSink.getFirstKeyPacket({ verifyKeyPackets: true }));
    if (!firstVideoPacket) {
      await input.dispose?.();
      throw new Error('The source has no decodable video keyframe');
    }

    // Audio begins at or just before the selected video keyframe to maintain
    // lip sync. Packet timestamps stay on the original movie timeline.
    let audioSink = null;
    let firstAudioPacket = null;
    if (audioTrack) {
      audioSink = new EncodedPacketSink(audioTrack);
      firstAudioPacket =
        (await audioSink.getPacket(firstVideoPacket.timestamp)) ||
        (await audioSink.getFirstPacket());
    }

    let durationSec = 0;
    try {
      durationSec =
        (await input.getDurationFromMetadata?.()) ??
        (await input.getDuration?.()) ??
        0;
    } catch (_) {}

    const mediaSource = new MediaSourceClass();
    let sourceBuffer = null;
    let objectUrl = null;
    let aborted = false;
    let playbackStarted = false;
    let output = null;
    let nativeSeekTimer = null;
    let onNativeSeeking = null;

    const revoke = () => {
      if (objectUrl) {
        try {
          URL.revokeObjectURL(objectUrl);
        } catch (_) {}
        objectUrl = null;
      }
    };

    const cancel = async () => {
      aborted = true;
      if (nativeSeekTimer !== null) {
        clearTimeout(nativeSeekTimer);
        nativeSeekTimer = null;
      }
      if (onNativeSeeking) {
        videoEl.removeEventListener('seeking', onNativeSeeking);
        onNativeSeeking = null;
      }
      try {
        await output?.cancel?.();
      } catch (_) {}
      try {
        await input.dispose?.();
      } catch (_) {}
      try {
        if (mediaSource.readyState === 'open') {
          mediaSource.endOfStream();
        }
      } catch (_) {}
      revoke();
    };

    const ready = new Promise((resolve, reject) => {
      const timer = setTimeout(
        () => reject(new Error('MediaSource sourceopen timed out')),
        20000
      );
      mediaSource.addEventListener(
        'sourceopen',
        async () => {
          try {
            sourceBuffer = mediaSource.addSourceBuffer(mimeType);
            if (durationSec && Number.isFinite(durationSec) && durationSec > 0) {
              mediaSource.duration = durationSec;
            }
            clearTimeout(timer);
            resolve();
          } catch (err) {
            clearTimeout(timer);
            reject(err);
          }
        },
        { once: true }
      );
    });

    // Attach to the native <video> (AVPlayer on iOS).
    if ('ManagedMediaSource' in window && mediaSource instanceof window.ManagedMediaSource) {
      try {
        videoEl.disableRemotePlayback = true;
      } catch (_) {}
      videoEl.srcObject = mediaSource;
    } else {
      objectUrl = URL.createObjectURL(mediaSource);
      videoEl.src = objectUrl;
    }
    videoEl.load();

    const evictBehind = async (sb) => {
      const ranges = sb.buffered;
      if (!ranges.length) return;
      const start = ranges.start(0);
      const playhead = videoEl.currentTime || ranges.end(ranges.length - 1);
      const removeEnd = Math.max(start, playhead - BUFFER_BEHIND_KEEP_SEC);
      if (removeEnd > start && !sb.updating) {
        sb.remove(start, removeEnd);
        await waitForUpdateEnd(sb);
      } else {
        await sleep(250);
      }
    };

    const appendInOrder = async (data) => {
      await ready;
      const sb = sourceBuffer;
      if (!sb) throw new Error('SourceBuffer unavailable');
      for (let attempt = 0; ; attempt++) {
        if (aborted) return;
        try {
          sb.appendBuffer(data);
          await waitForUpdateEnd(sb);
          if (!playbackStarted && sb.buffered.length > 0) {
            playbackStarted = true;
            const duration = Number.isFinite(videoEl.duration)
              ? videoEl.duration
              : startTime;
            videoEl.currentTime = Math.min(
              startTime,
              Math.max(0, duration - 0.05)
            );
            if (autoplay) videoEl.play().catch(() => {});
          }
          return;
        } catch (error) {
          if (error && error.name === 'QuotaExceededError' && attempt < MAX_QUOTA_RETRIES) {
            await evictBehind(sb);
            continue;
          }
          throw error;
        }
      }
    };

    const applyBackpressure = async (sb) => {
      while (!aborted) {
        if (bufferedAheadOf(sb, videoEl.currentTime || 0) < BUFFER_AHEAD_HIGH_SEC) {
          return;
        }
        await sleep(200);
      }
    };

    const writable = new WritableStream({
      async write(chunk) {
        if (aborted) return;
        // StreamTargetChunk: { data, position } — fragmented MP4 is append-only.
        const data = chunk && chunk.data ? chunk.data : chunk;
        await appendInOrder(data);
        if (sourceBuffer) await applyBackpressure(sourceBuffer);
      },
    });

    const TargetClass = AppendOnlyStreamTarget || StreamTarget;
    const target =
      TargetClass === AppendOnlyStreamTarget
        ? new AppendOnlyStreamTarget(writable)
        : new StreamTarget(writable);

    output = new Output({
      format: new Mp4OutputFormat({ fastStart: 'fragmented' }),
      target,
    });

    const videoPacketSource = new EncodedVideoPacketSource(videoCodec);
    output.addVideoTrack(videoPacketSource, {
      decoderConfig: videoDecoderConfig,
      rotation: await videoTrack.getRotation(),
      primingPacket: firstVideoPacket,
    });

    let audioPacketSource = null;
    if (audioTrack && audioCodec && audioDecoderConfig && firstAudioPacket) {
      audioPacketSource = new EncodedAudioPacketSource(audioCodec);
      output.addAudioTrack(audioPacketSource, {
        decoderConfig: audioDecoderConfig,
        primingPacket: firstAudioPacket,
      });
    }

    const seek = async (requestedTime) => {
      if (aborted) return;
      const duration = Number.isFinite(videoEl.duration)
        ? videoEl.duration
        : requestedTime;
      const targetTime = Math.min(
        Math.max(0, Number(requestedTime) || 0),
        Math.max(0, duration - 0.05)
      );

      if (sourceBuffer && isBufferedAt(sourceBuffer, targetTime)) {
        videoEl.currentTime = targetTime;
        return;
      }

      const shouldResume = !videoEl.paused;
      await cancel();
      if (sessions.get(videoEl)?.cancel === cancel) {
        sessions.delete(videoEl);
      }
      await startRemux(videoEl, url, targetTime, shouldResume);
    };

    sessions.set(videoEl, { cancel, seek, revoke });

    // Native Safari controls mutate currentTime without calling Dart. Detect
    // seeks outside the active MSE range and replace the session after the
    // scrub gesture settles.
    onNativeSeeking = () => {
      if (aborted || !sourceBuffer) return;
      const requested = videoEl.currentTime;
      if (!Number.isFinite(requested) || isBufferedAt(sourceBuffer, requested)) {
        return;
      }
      if (nativeSeekTimer !== null) clearTimeout(nativeSeekTimer);
      nativeSeekTimer = setTimeout(() => {
        nativeSeekTimer = null;
        seek(requested).catch((error) => {
          if (!aborted) console.error('[HopeTvNativeVod] native seek failed', error);
        });
      }, 160);
    };
    videoEl.addEventListener('seeking', onNativeSeeking);

    const pipePackets = async (sink, packetSource, firstPacket, decoderConfig) => {
      if (!sink || !packetSource || !firstPacket) return;
      let isFirst = true;
      try {
        for await (const packet of sink.packets(firstPacket)) {
          if (aborted) return;
          await packetSource.add(
            packet,
            isFirst ? { decoderConfig } : undefined
          );
          isFirst = false;
        }
      } finally {
        packetSource.close();
      }
    };

    (async () => {
      await output.start();
      await Promise.all([
        pipePackets(videoSink, videoPacketSource, firstVideoPacket, videoDecoderConfig),
        pipePackets(audioSink, audioPacketSource, firstAudioPacket, audioDecoderConfig),
      ]);
      if (!aborted) await output.finalize();
      try {
        if (!aborted && mediaSource.readyState === 'open') {
          mediaSource.endOfStream();
        }
      } catch (_) {}
    })().catch((err) => {
      if (!aborted) {
        console.error('[HopeTvNativeVod] packet-copy remux failed', err);
        try {
          if (mediaSource.readyState === 'open') {
            mediaSource.endOfStream('decode');
          }
        } catch (_) {}
      }
    });

    return { mode: 'remux-mse' };
  }

  async function seek(videoEl, time) {
    const session = sessions.get(videoEl);
    if (session?.seek) {
      await session.seek(time);
      return;
    }
    videoEl.currentTime = Math.max(0, Number(time) || 0);
  }

  window.HopeTvNativeVod = {
    play,
    seek,
    stop,
    needsRemux(url) {
      const u = String(url || '').toLowerCase();
      return (
        u.includes('/movie/') ||
        u.includes('/series/') ||
        u.includes('.mkv') ||
        u.includes('.avi')
      );
    },
  };
})();
