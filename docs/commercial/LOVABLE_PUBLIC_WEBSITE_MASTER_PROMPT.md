# HOPE TV — Lovable public website master prompt

Copy everything inside the prompt block below into a **new Lovable project**. This public website must remain separate from the private `hope-tv-insights` owner dashboard.

---

## Master prompt

Build a production-ready, bilingual public marketing website for an entertainment application named **HOPE TV**.

This must be a completely separate public website. Do not modify, recreate, expose, or link into the private owner/admin dashboard. The production public domain is `https://hope-tv.site`; the private dashboard uses `https://admin.hope-tv.site` and must not appear in public navigation.

### 1. Absolute naming rule

Publicly, the product is called only:

```text
HOPE TV
```

Do not use the legacy three-letter industry acronym anywhere in:

- Visible copy.
- Page titles or descriptions.
- SEO metadata.
- Open Graph metadata.
- Image alt text.
- Navigation labels.
- Route names.
- Component names intended for public output.
- Generated images.
- Logo subtitles.
- Footer text.
- FAQs.
- Comments or placeholder content that could ship to production.

Do not describe HOPE TV as a content seller or claim it includes a catalog. HOPE TV is a polished viewing and media-organization application. It does not provide, sell, host, or bundle media content. Users connect content they are already authorized to access.

### 2. Brand asset treatment

Use the supplied HOPE logo as the visual reference. In the source repository the reference asset is:

```text
assets/icons/app_logo.png
```

The reference image contains:

- A folded ribbon-style capital `H` emblem.
- Cyan-to-electric-blue gradients.
- A soft blue glow on a deep navy-black background.
- A metallic white `HOPE` wordmark.
- A legacy subtitle that must never appear on the public website.

For the website:

1. Use only the ribbon `H` emblem from the supplied asset.
2. Never render the original full image because its lower subtitle is not part of the public brand.
3. Create a clean emblem-only derivative asset from the supplied logo while preserving the original shape, proportions, cyan/blue gradient, highlights, and glow.
4. Pair the emblem with a newly typeset wordmark reading exactly `HOPE TV`.
5. Do not redraw the emblem into a generic play button, television outline, antenna, film strip, or letter inside a circle.
6. Do not add a slogan inside the logo lockup.
7. Provide horizontal and compact logo lockups suitable for the navbar, footer, favicon, and social preview.
8. Preserve generous clear space around the emblem.

If an emblem-only source asset is not available, create the derivative from the uploaded reference image before building the header. Do not approximate the emblem with an unrelated icon.

### 3. Existing product design system

The website must look like the same product as the current HOPE TV application. Use these exact design tokens as the foundation.

#### Core colors

```css
--hope-accent: #00C2FF;
--hope-accent-dim: #0091BF;
--hope-accent-blue: #0077FF;
--hope-accent-glow: rgba(0, 194, 255, 0.15);

--hope-bg-0: #08090B;
--hope-bg-1: #0E1014;
--hope-bg-2: #14171D;
--hope-bg-3: #1B1F28;
--hope-bg-4: #242938;

--hope-text-primary: #F0F2F5;
--hope-text-secondary: #8E96A8;
--hope-text-disabled: #4A5060;
--hope-text-on-accent: #001822;

--hope-border: rgba(255, 255, 255, 0.12);
--hope-border-focused: rgba(0, 194, 255, 0.30);

--hope-success: #2ECC71;
--hope-warning: #F39C12;
--hope-error: #E74C3C;
```

#### Gradients and atmosphere

- Primary action gradient: `linear-gradient(135deg, #00C2FF 0%, #0077FF 100%)`.
- Page background: deep `#08090B` with a restrained top wash from `#10242D` fading into the base background.
- Hero/media overlays: layered dark directional scrims using near-black navy, never a purple gradient.
- Glass surfaces: approximately `rgba(16, 20, 28, 0.82)` with a subtle white 12% border and restrained backdrop blur.
- Focused/featured elements may use a cyan glow, but do not place neon glows around every card.

#### Typography

- English/Latin: **Noto Sans**, weights 400, 500, 600, and 700.
- Arabic: **Cairo**, weights 400, 500, 600, and 700.
- Use locally hosted font files where possible; avoid runtime font dependencies.
- Headlines should be bold and cinematic without becoming oversized billboard text.
- Body copy must remain comfortable and readable with approximately 1.5–1.7 line height.

#### Shape, spacing, and elevation

- Use an 8px spacing grid with useful increments: 4, 8, 12, 16, 20, 24, 32, 40, 48, and 64.
- Default button radius: 8px.
- Default card radius: 12px.
- Large feature/glass panel radius: 16px.
- Chips may be fully rounded.
- Use hairline borders and subtle dark shadows.
- Avoid excessive rounded containers and nested cards.

#### Motion

- Motion must feel fast, restrained, and premium.
- Use `ease-out`/`cubic-bezier` transitions around 120–240ms for controls.
- Use subtle reveal motion only when it improves hierarchy.
- Respect `prefers-reduced-motion` and remove nonessential movement.
- No parallax-heavy pages, continuous floating objects, animated gradient blobs, cursor followers, or autoplay background video.

### 4. Visual direction

Create a premium, cinematic, dark entertainment experience with the calm precision of a modern TV interface.

The site should feel:

- Confident.
- Fast.
- Cinematic.
- Technically polished.
- Trustworthy.
- Designed for large screens as well as phones.

Use the existing product patterns:

- Deep layered black/navy surfaces.
- Cyan focus accents.
- Full-width cinematic hero composition.
- Direction-aware gradient scrims behind text.
- Crisp content rails or device mockups.
- Frosted glass only where it supports focus.
- Strong, simple calls to action.

Avoid generic AI-generated landing-page styling:

- No purple/pink gradients.
- No random glowing orbs.
- No giant pill buttons everywhere.
- No fake 3D glass spheres.
- No endless grids of identical feature cards.
- No emojis as product icons.
- No fake awards, user counts, ratings, reviews, or partner logos.
- No stock photos of people watching television.
- No copyrighted movie posters, broadcaster logos, or third-party entertainment artwork.
- No claims such as “unlimited content,” “all channels,” or “thousands of movies.”
- No invented pricing or subscription plans.

### 5. Site structure

Build one polished, responsive homepage with these sections.

#### A. Sticky navigation

Include:

- HOPE TV emblem and wordmark.
- Links: Features, Experience, Platforms, Privacy, FAQ.
- Language switcher: `EN` / `العربية`.
- Primary action: `Download HOPE TV` / `تحميل HOPE TV`.

The navbar begins transparent over the hero and gains a subtle `#0E1014` glass surface with a hairline border after scrolling.

On mobile, use a compact accessible menu. Do not hide the language switcher inside an obscure settings screen.

#### B. Hero

Use a two-column cinematic layout on desktop and a focused single-column layout on mobile.

English copy direction:

```text
Eyebrow: Made for every screen
Headline: Entertainment, beautifully organized.
Body: HOPE TV brings live viewing, movies, series, favorites, and watch history into one fast, polished experience across your screens.
Primary CTA: Download HOPE TV
Secondary CTA: Explore the experience
Support line: Use HOPE TV with content you are authorized to access.
```

Arabic copy direction:

```text
Eyebrow: مصمم لكل شاشة
Headline: ترفيهك، مرتب بشكل أجمل.
Body: يجمع HOPE TV المشاهدة المباشرة والأفلام والمسلسلات والمفضلة وسجل المشاهدة في تجربة سريعة وأنيقة على جميع شاشاتك.
Primary CTA: تحميل HOPE TV
Secondary CTA: اكتشف التجربة
Support line: استخدم HOPE TV مع المحتوى المصرح لك بالوصول إليه.
```

The visual side should show an original device composition using real HOPE TV screenshots if supplied. If screenshots are unavailable, create neutral interface mockups based on the actual design system—dark media rails, guide rows, focus states, and a player surface—without copyrighted posters or fabricated third-party content.

Do not use a generic stock-image hero.

#### C. Product experience strip

Create a restrained horizontal strip showing the experience across:

- TV.
- Android phone/tablet.
- Windows desktop.
- Web.

Use device silhouettes sparingly. The content should feel like one adaptive product, not four separate products.

Suggested labels:

```text
TV-first navigation
Fast on every screen
One familiar experience
```

Arabic:

```text
تنقل مصمم للتلفاز
سرعة على كل شاشة
تجربة واحدة مألوفة
```

#### D. Core features

Use one asymmetrical editorial layout instead of a generic equal-card grid. Feature these real capabilities:

1. Cinematic home experience.
2. Live viewing and program guide.
3. Movies and series organization.
4. Favorites and continue watching.
5. Search across the connected library.
6. Audio tracks, subtitles, and playback controls.
7. Hardware-accelerated playback where supported.
8. Arabic and English interface with true RTL support.

Keep descriptions short and factual. Do not imply that HOPE TV supplies the media.

#### E. Focused player showcase

Create a dark full-width section that resembles the current player experience:

- Minimal chrome.
- Large playback surface.
- Track/subtitle controls.
- Quality and playback settings.
- Keyboard, touch, and remote-friendly interactions.

Use a fictional abstract demo title such as `Night Horizon` and original gradient artwork. Do not use real films, channels, sports brands, or broadcaster marks.

#### F. Privacy and trust

Use a calm section with no fear-based language.

Approved themes:

- Viewing-source credentials are designed to stay in secure device storage.
- Sensitive viewing URLs and credentials are excluded from analytics.
- HOPE TV account access is separate from any external viewing source.
- The application does not provide or host media content.

Suggested heading:

```text
Your experience stays yours.
```

Arabic:

```text
تجربتك تظل ملكك.
```

Do not make absolute security claims such as “100% secure,” “unhackable,” or “zero data collection.”

#### G. Download section

GitHub Releases is the canonical source for Android and Windows builds. Cloudflare R2 is not used.

Read the release destination from a public deployment variable:

```text
PUBLIC_RELEASES_URL=<owner-provided GitHub latest-release URL>
```

Do not print the raw repository URL as visible text. Provide clear platform actions:

- Download for Android.
- Download for Windows.
- Open the web experience only if a confirmed public web-app URL is provided separately.

Both download actions may route to `PUBLIC_RELEASES_URL` unless stable direct asset URLs are supplied. Open external download links safely with clear external-link affordances. Do not embed any GitHub token or Supabase service-role key.

Do not mention R2, a download gateway, or `downloads.hope-tv.site`.

#### H. FAQ

Include concise answers to:

1. What is HOPE TV?
2. Does HOPE TV include media content?
3. Which platforms are supported?
4. Does HOPE TV support Arabic?
5. Where can I download updates?
6. How do I contact support?

Required content answer:

```text
HOPE TV is a viewing and media-organization application. It does not provide, sell, host, or bundle media content. Use it only with content you are authorized to access.
```

Provide an equivalent natural Arabic answer, not a literal low-quality translation.

#### I. Footer

Include:

- Emblem and `HOPE TV` wordmark.
- Short product description.
- Features, Platforms, Privacy, Terms, and Support links.
- Support email: `support@hope-tv.site`.
- Current year generated dynamically.
- Language switcher.

Do not include the admin dashboard link.

### 6. Bilingual and RTL requirements

English and Arabic are first-class languages.

1. Store copy in a clean typed locale dictionary or translation files.
2. Switching language must update all text, metadata where supported, direction, alignment, icons that imply direction, and navigation behavior.
3. Set `dir="rtl"` for Arabic and `dir="ltr"` for English at the document level.
4. Use logical CSS properties such as inline-start/inline-end rather than hardcoded left/right where possible.
5. Use Cairo for Arabic and Noto Sans for English.
6. Persist the selected language locally.
7. Default to browser language when it is Arabic; otherwise default to English.
8. Do not mix untranslated English UI labels into the Arabic version except the brand name `HOPE TV`.

### 7. Functional requirements

- Use the existing Lovable-supported React + TypeScript stack.
- Build reusable components rather than one monolithic page component.
- Centralize brand tokens and public constants.
- Keep downloads and support addresses in a small typed configuration module.
- Do not add a database or authentication flow to the public marketing website.
- Do not connect the public website to private admin APIs.
- Do not expose Supabase service-role credentials.
- Do not create fake newsletter or contact-form submission behavior.
- If a contact form is included, it must use a real approved backend; otherwise use a simple `mailto:support@hope-tv.site` action.
- Use semantic HTML landmarks and heading order.
- Ensure all controls work with keyboard navigation.
- Provide visible focus states using `#00C2FF`.
- Ensure touch targets are at least 44×44px.
- Meet WCAG AA contrast for body text and controls.
- Add a skip-to-content link.
- Respect reduced motion.
- Make all responsive states intentional at mobile, tablet, laptop, desktop, and ultrawide widths.

### 8. SEO and metadata

Use:

```text
Canonical URL: https://hope-tv.site/
English title: HOPE TV — Entertainment, beautifully organized
Arabic title: HOPE TV — ترفيهك، مرتب بشكل أجمل
```

Create concise descriptions that explain HOPE TV as a cross-platform viewing and media-organization application without implying that content is included.

Also provide:

- Canonical tag.
- Open Graph title, description, URL, and image.
- Twitter/X card metadata.
- Favicon based on the emblem-only asset.
- Web app theme color `#08090B`.
- `robots.txt`.
- `sitemap.xml` for public routes.
- Organization and SoftwareApplication structured data using only verified facts.

Do not add fake aggregate ratings, prices, offers, download counts, or review schema.

### 9. Performance requirements

- Target Lighthouse scores of 90+ for Performance, Accessibility, Best Practices, and SEO on a production build.
- Optimize and correctly size the emblem, screenshots, and social preview.
- Use AVIF/WebP where appropriate with responsive sources.
- Lazy-load below-the-fold images.
- Avoid large animation libraries unless already required.
- Avoid autoplay video.
- Prevent layout shift by reserving media dimensions.
- Keep the initial route lightweight.
- Do not fetch third-party media catalogs.

### 10. Required project structure

Use a clean structure similar to:

```text
src/
  components/
    brand/
    layout/
    sections/
    ui/
  config/
    public-site.ts
  i18n/
    en.ts
    ar.ts
  pages/ or routes/
  styles/
    tokens.css
public/
  brand/
  images/
  robots.txt
  sitemap.xml
```

Adapt this to the actual Lovable project conventions instead of forcing unnecessary rewrites.

### 11. Acceptance criteria

Do not consider the task complete until all of the following are true:

- The public site uses only the name `HOPE TV`.
- The banned legacy acronym does not appear anywhere in rendered output or public metadata.
- The original full logo with the old subtitle is never rendered.
- The emblem shape and cyan/blue treatment remain consistent with the supplied logo.
- Colors, typography, spacing, radii, glass surfaces, and motion match the current application.
- English and Arabic versions are complete and polished.
- Arabic layout is genuinely RTL.
- No fake claims, metrics, reviews, pricing, or media catalog are present.
- The site clearly states that HOPE TV does not provide media content.
- Android and Windows downloads lead to GitHub Releases.
- No R2 or download-gateway architecture is introduced.
- No admin routes, private APIs, or privileged keys are present.
- Responsive layouts work without horizontal overflow.
- Keyboard focus, contrast, reduced motion, alt text, and semantic headings are verified.
- Production build, type checking, and linting pass.

### 12. Final delivery

At completion, provide:

1. A concise summary of the implemented design.
2. A list of created/modified files.
3. The exact place to replace the emblem-only asset and product screenshots.
4. The configuration location for GitHub Releases and support email.
5. Build, lint, type-check, and accessibility results.
6. Any facts or assets still requiring owner confirmation.

Do not stop at a wireframe or written plan. Implement the complete responsive website with production-quality content, interactions, and styling.

---

## Assets to provide to Lovable

Before or immediately after submitting the prompt, provide:

1. The current logo reference from `assets/icons/app_logo.png`.
2. An emblem-only transparent PNG or SVG if available.
3. Real HOPE TV screenshots for TV, Android, Windows, and Web if approved for public use.
4. Any finalized Privacy Policy and Terms URLs.

Do not provide screenshots that expose usernames, server addresses, credentials, account identifiers, private media URLs, or admin data.
