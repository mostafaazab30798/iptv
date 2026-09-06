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

  const PASSTHROUGH_VIDEO = new Set(['avc', 'vp9', 'av1']);
  const PASSTHROUGH_AUDIO = new Set(['aac', 'mp3', 'opus']);
  const BUFFER_AHEAD_HIGH_SEC = 30;
  const BUFFER_BEHIND_KEEP_SEC = 10;
  const MAX_QUOTA_RETRIES = 8;

  /** @type {WeakMap<HTMLVideoElement, { cancel: () => Promise<void>, revoke?: () => void }>} */
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
      return { ct, isMkv, isMp4, ok: res.ok || res.status === 206 };
    } catch (_) {
      return { ct: '', isMkv: false, isMp4: false, ok: false };
    }
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
   * @returns {Promise<{ mode: string }>}
   */
  async function play(videoEl, url) {
    await stop(videoEl);

    const probe = await probeContentType(url);
    // True MP4 can go straight to AVPlayer.
    if (probe.isMp4 || (probe.ct.includes('mp4') && !probe.isMkv)) {
      videoEl.src = url;
      videoEl.load();
      try {
        await videoEl.play();
      } catch (_) {}
      return { mode: 'direct-mp4' };
    }

    const MediaSourceClass = getMediaSourceClass();
    if (!MediaSourceClass) {
      throw new Error('MediaSource is not available in this browser');
    }

    const mb = await loadMediabunny();
    const {
      Input,
      Output,
      Conversion,
      UrlSource,
      ALL_FORMATS,
      Mp4OutputFormat,
      StreamTarget,
      AppendOnlyStreamTarget,
    } = mb;

    const input = new Input({
      source: new UrlSource(url, { maxCacheSize: 16 * 1024 * 1024, parallelism: 2 }),
      formats: ALL_FORMATS,
    });

    const videoTrack = await input.getPrimaryVideoTrack();
    const videoCodec = videoTrack ? await videoTrack.getCodec() : null;
    if (!(videoTrack && videoCodec && PASSTHROUGH_VIDEO.has(videoCodec))) {
      // Fall back: still try remux/transcode path with known AVC output mime.
      // Progressive MSE needs a known codec string up front when possible.
    }

    let videoCodecString = null;
    if (videoTrack && videoCodec && PASSTHROUGH_VIDEO.has(videoCodec)) {
      videoCodecString = await videoTrack.getCodecParameterString();
    }

    const audioTrack = await input.getPrimaryAudioTrack();
    let audioCodecString = null;
    if (audioTrack) {
      const audioCodec = await audioTrack.getCodec();
      audioCodecString =
        audioCodec && PASSTHROUGH_AUDIO.has(audioCodec)
          ? await audioTrack.getCodecParameterString()
          : 'mp4a.40.2'; // AAC-LC when we re-encode
    }

    // If we cannot know the video codec string (needs re-encode), use a common AVC mime.
    if (!videoCodecString) {
      videoCodecString = 'avc1.640028';
    }

    const codecList = audioCodecString
      ? `${videoCodecString}, ${audioCodecString}`
      : videoCodecString;
    const mimeType = `video/mp4; codecs="${codecList}"`;
    if (
      typeof MediaSourceClass.isTypeSupported === 'function' &&
      !MediaSourceClass.isTypeSupported(mimeType)
    ) {
      throw new Error(`Unsupported MSE mime: ${mimeType}`);
    }

    const mediaSource = new MediaSourceClass();
    let sourceBuffer = null;
    let objectUrl = null;
    let aborted = false;
    /** @type {{ cancel: () => Promise<void> } | null} */
    let conversion = null;

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
      try {
        await conversion?.cancel?.();
      } catch (_) {}
      try {
        if (mediaSource.readyState === 'open') {
          mediaSource.endOfStream();
        }
      } catch (_) {}
      revoke();
    };

    sessions.set(videoEl, { cancel, revoke });

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
            try {
              const durationSec =
                (await input.getDurationFromMetadata?.()) ??
                (await input.getDuration?.());
              if (durationSec && Number.isFinite(durationSec) && durationSec > 0) {
                mediaSource.duration = durationSec;
              }
            } catch (_) {}
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

    conversion = await Conversion.init({
      input,
      output: new Output({
        format: new Mp4OutputFormat({ fastStart: 'fragmented' }),
        target,
      }),
      video: async (track) => {
        const codec = await track.getCodec();
        return codec && PASSTHROUGH_VIDEO.has(codec) ? {} : { codec: 'avc' };
      },
      audio: async (track) => {
        const codec = await track.getCodec();
        return codec && PASSTHROUGH_AUDIO.has(codec)
          ? {}
          : { codec: 'aac', numberOfChannels: 2, sampleRate: 48000 };
      },
    });

    if (!conversion.isValid) {
      const reason = conversion.discardedTracks?.[0]?.reason ?? 'invalid conversion';
      await cancel();
      throw new Error(`Cannot remux VOD for native player (${reason})`);
    }

    sessions.set(videoEl, { cancel, revoke });

    // Start playback as soon as the first fragments land.
    ready.then(() => {
      videoEl.play().catch(() => {});
    });

    conversion.execute().then(() => {
      try {
        if (!aborted && mediaSource.readyState === 'open') {
          mediaSource.endOfStream();
        }
      } catch (_) {}
    }).catch((err) => {
      if (!aborted) {
        console.error('[HopeTvNativeVod] remux failed', err);
      }
    });

    return { mode: 'remux-mse' };
  }

  window.HopeTvNativeVod = {
    play,
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
