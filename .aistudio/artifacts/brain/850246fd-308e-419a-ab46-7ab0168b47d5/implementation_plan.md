# Naam — Viewport Fit, Twitter-Style Micro-Interactions, Liquid Glass Presence & Full-Screen Chat

This update eliminates vertical scrolling on the Discover screen so the 5 action buttons are always immediately visible in the viewport, adds Twitter/X-inspired radial burst and spring micro-interactions on the action buttons, replaces the solid pink Online badge with a translucent Liquid Glass presence pill (with a green dot for `"Online"` or `"Seen 1h ago"` / `"Seen 1d ago"` / `"Seen 2d ago"`), and upgrades the open conversation view into a true full-screen chat experience with no bottom navigation bar.

## User Review & Critical Decisions

> [!IMPORTANT]
> All four improvements requested in your feedback are specified below and will be applied across both the interactive Next.js preview and the Flutter mobile app.

- **Zero-Scroll Discover Viewport Fit**: The Discover stage locks to the exact height between the top header and bottom tab bar (`flex: 1; min-height: 0; overflow: hidden`), sizing the portrait card dynamically so the 5 action buttons (`Rewind`, `Skip`, `Love`, `Star`, `Message`) are always visible without scrolling while staying completely fixed across photo changes.
- **Twitter/X-Style Button Micro-Interactions**: Tapping the **Love** button triggers a filled heart spring pop, an expanding crimson ring wave, and a radial 8-particle burst before gliding to the next profile. **Skip**, **Star**, and **Rewind** include matching tactile ring ripples and spring icon feedback.
- **Liquid Glass Presence Pills (`Online` & `Seen ... ago`)**: Removed the solid pink `Online` badge on the Likes grid and Discover card. Presence is now displayed in a frosted Liquid Glass pill (`backdrop-filter: blur(16px) saturate(180%)`, subtle specular border) with a glowing emerald green dot (`#22C55E`) for `Online`, or a frosted glass pill showing `Seen 1h ago`, `Seen 1d ago`, or `Seen 2d ago`.
- **Full-Screen Dedicated Chat Conversation View**: Opening any chat thread hides the bottom 4-tab navigation bar completely and renders a full-screen native chat layout with a sticky partner header (back button, avatar, name, verified icon, and live/last-seen status), full-bleed scrollable message stream with timestamps, and a docked bottom message composer bar.

---

## 1. Overview & Core Concept

- **What It Does**: Delivers a zero-scroll, one-handed Discover experience, tactile Twitter-grade button micro-interactions, realistic Liquid Glass activity status indicators across Discover/Likes/Chat, and a distraction-free full-screen chat screen.
- **Target Audience / Persona**: Intentional daters on iOS, Android, and mobile web expecting native-grade spatial polish and immediate visual feedback.
- **Key Value**: Eliminates accidental scrolling to reach core swipe actions, clarifies user activity status with refined glassmorphic aesthetics, and gives conversations full vertical screen real estate.

---

## 2. User Experience & Visual Design

- **Key User Flows**:
  - **Discover (Zero-Scroll Viewport & Presence)**:
    - The top bar, portrait card, and 5 circular action buttons fit 100% within `100dvh` with no vertical scrollbar.
    - A translucent **Liquid Glass presence pill** sits at the top-left of the portrait card (below the story indicator bars) showing either a glowing green dot + `Online` or `Seen 1h ago` / `Seen 1d ago` / `Seen 2d ago`.
    - Tapping **Love** triggers an immediate Twitter-style heart fill, expanding ring ripple, and 8-dot radial confetti burst (`220ms`) synchronized with a smooth card glide.
  - **Likes Grid (Liquid Glass Online & Last Seen Badges)**:
    - Each card in the 2-column Likes grid displays the new translucent Liquid Glass presence pill (emerald green dot + `Online`, or frosted `Seen 1h ago` / `Seen 1d ago` / `Seen 2d ago`) alongside the frosted `Verified` badge—with zero pink background fill on the Online badge.
  - **Full-Screen Inside-Chat Experience**:
    - Tapping any match or conversation row opens a full-bleed screen that **hides the bottom 4-tab navigation bar**.
    - Includes a sticky glass header (Back button, tappable partner avatar & name, Verified badge, and `Online` / `Seen ... ago` subtitle), a scrollable message canvas with date/match context pills and read timestamps, and a docked bottom composer capsule.

- **Visual Identity & Theme**:
  - *Liquid Glass Presence Pill*: `background: rgba(15, 15, 20, 0.42)`, `backdrop-filter: blur(16px) saturate(180%)`, `border: 1px solid rgba(255, 255, 255, 0.24)`, `box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.25)`, crisp white typography (`11px`, `600` weight), and `#22C55E` emerald dot with soft outer glow (`0 0 8px rgba(34, 197, 94, 0.8)`).
  - *Twitter-Style Heart Burst*: `#F93666` primary heart fill with radial micro-particles in `#F93666`, `#FF6B8B`, `#FFB3C6`, and `#F59E0B` expanding outward over `220ms` (`cubic-bezier(0.16, 1, 0.3, 1)`).

---

## 3. Key Product Decisions & Trade-Offs

- **Decision 1: Dynamic Flex Viewport Sizing (`flex: 1; min-height: 0`) vs. Hardcoded `500px` Card Height**
  - *Chosen Approach*: Use `flex: 1; min-height: 0` on the portrait card inside a locked non-scrolling Discover stage (`overflow: hidden`), while keeping the bottom identity overlay height fixed (`92px`).
  - *Why*: Guarantees the portrait card fills the maximum available height on any mobile or desktop preview screen without ever pushing the 5 action buttons below the fold, while ensuring photo-to-photo transitions never shift layout geometry.
- **Decision 2: Full-Screen Modal Route for Open Chat Threads**
  - *Chosen Approach*: Conditionally suppress the bottom tab bar whenever `fullScreenChatThread` (or `fullScreenProfile`) is active, and anchor the message composer directly to the bottom safe area.
  - *Why*: Matches iOS/Android messaging standards (iMessage, WhatsApp, Hinge) where open conversations occupy the entire screen without tab bar clutter.

---

## 4. Technical Architecture & Data Strategy *(Technical Reference)*

### Architecture & Component Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     Naam Mobile Viewport (100dvh)                        │
├───────────────────────────────────┬──────────────────────────────────────┤
│   Standard 4-Tab Shell            │   Full-Screen Dedicated Chat View    │
│   (Bottom Tab Bar Visible)        │   (Bottom Tab Bar Hidden)            │
│                                   │                                      │
│  ┌─────────────────────────────┐  │  ┌────────────────────────────────┐  │
│  │ Discover Stage (No Scroll)  │  │  │ Sticky Chat Partner Header     │  │
│  │ ├─ Flex-1 Portrait Card     │  │  │ ├─ Back Button                 │  │
│  │ │  ├─ Story Bars            │  │  │ ├─ Avatar + Name + Verified    │  │
│  │ │  ├─ Liquid Glass Presence │  │  │ └─ Green Dot Online / Seen Ago │  │
│  │ │  └─ Fixed 92px Bio Stack  │  │  ├────────────────────────────────┤  │
│  │ └─ Docked 5-Action Row      │  │  │ Full-Bleed Message Stream      │  │
│  │    └─ Twitter Burst Effect  │  │  │ ├─ Match Context Pill          │  │
│  ├─────────────────────────────┤  │  │ └─ Timestamped Chat Bubbles    │  │
│  │ Likes Grid                  │  │  ├────────────────────────────────┤  │
│  │ └─ Liquid Glass Status Pill │  │  │ Docked Bottom Composer Bar     │  │
│  └─────────────────────────────┘  │  └────────────────────────────────┘  │
└───────────────────────────────────┴──────────────────────────────────────┘
```

### Data Model & Presence Mapping

- **`CandidateProfile` Presence Field (`lastSeenLabel: string`)**:
  - Online candidates (`isOnline: true`): Display `Online` with a glowing `#22C55E` emerald dot inside the Liquid Glass pill.
  - Offline candidates (`isOnline: false`): Display realistic relative timestamps (`Seen 1h ago`, `Seen 1d ago`, `Seen 2d ago`) with a soft frosted glass dot inside the Liquid Glass pill.
- **Interactive State Transitions**:
  - Clicking **Love**, **Skip**, **Star**, or **Rewind** triggers `burstAction` state on the clicked button (rendering the radial particle ring + icon spring animation) while smoothly transitioning the card deck.
  - Opening a chat thread sets `fullScreenChatThread`, immediately hiding `.bottomTabBarWrapper` and mounting the full-screen chat layout with auto-scroll to the latest message.
