# Implementation Plan — `naam` Welcome & 8-Step Onboarding Flow

## 1. Overview & Entry Flow
- **Launch State**: The application will start on the new **Welcome Screen** (`step 0`) and progress through the **8-Step Onboarding Flow** (`01 / 08` through `08 / 08`).
- **Completion & Log In**:
  - Completing Step `08 / 08` (`Capture selfie`) transitions into the main **naam** Discovery experience with all onboarding inputs (First Name, calculated Age, Gender, Relationship Intention, Photos, City & Distance, and Verified status) synced to the user's profile.
  - Clicking `"Log in"` on the Welcome screen allows returning users to jump directly to the mobile number / OTP verification or into the app.
  - A `"Replay Onboarding / Log out"` action in the Profile screen lets you revisit the Welcome and 8-step onboarding flow anytime.
- **Brand Copy Alignment**: The legal/consent text in Steps `03 / 08` and `08 / 08` will use **naam** (`"naam is for adults aged 18 and over."` and `"I agree to naam using my selfie and profile photos..."`).

---

## 2. Screen-by-Screen Specification (Exact Match to Reference Screenshots)

### Screen 0: Welcome Screen (`image_2972c48f.png`)
- **Top 62% Hero Image**: Full-bleed lifestyle photo of the Malayali couple holding chai and vada against the bright blue sky, with the white `naam` + hot-pink ribbon heart logo centered at the top.
- **Bottom 38% White Sheet**:
  - Centered bold headline: `"Someone new.\nSomething familiar."`
  - Subtitle: `"Meet Malayali singles who get you."`
  - Full-width gradient pill CTA (`linear-gradient(90deg, #FA0B65, #E21162)`): `"Let's begin"`
  - Secondary row: `"Already here? "` + hot-pink `"Log in"` action
  - Legal footer: `"For adults 18+ · By continuing, you agree to our Terms and Privacy Policy."` with underlined `Terms` and `Privacy Policy`.

### Shared Onboarding Header (`01 / 08` – `08 / 08`)
- **Top Row**: Left back button (`←`), centered `naam` logo (`/assets/aistudio/image_cd9da323.png`), right tabular step counter (`01 / 08` to `08 / 08`).
- **8-Segment Progress Bar**:
  - Completed segments (`< currentStep`): dark charcoal grey (`#6E6E73`)
  - Active segment (`=== currentStep`): hot pink (`#F7196B`)
  - Upcoming segments (`> currentStep`): soft light grey (`#E5E5EA`)
- **Bottom Sticky Action Bar**: Full-width rounded pill button (`height: 58px`, `#F7196B` gradient) with left-aligned label and right-aligned `→` arrow.

### Step `01 / 08` — Mobile Number (`image_5d3a073c.png`)
- **Heading**: `"Your number?"` & subtitle `"We'll send a one-time code to this number."`
- **Input Card**: `"Mobile number"` label above a rounded `20px` input container with country code selector (`+91` + pink chevron), pink vertical divider, and phone number input (`98765 43210`).
- **Privacy Note**: Outline lock icon + `"Your number stays private. It's only for sign-in and verification."`
- **CTA**: `"Send SMS code"` + `→`.

### Step `02 / 08` — Enter Your Code (`image_5a5ea85b.png`)
- **Heading**: `"Enter your code"` & subtitle `"We sent a 6-digit code by SMS."`
- **Number Bar**: Masked number (`+91 ••••• •3210`) on the left and underlined pink `"Change number"` button on the right (returns to Step 01).
- **OTP Grid**: `"SMS code"` label + 6 individual rounded digit boxes (`52×60px`), active box showing a pink vertical caret and empty boxes showing a pink dash (`-`), with auto-advance on digit entry.
- **Resend Prompt**: `"Didn't get a text? "` + underlined pink `"Resend code"`.
- **CTA**: `"Verify & continue"` + `→`.

### Step `03 / 08` — Name & Birthday (`image_262f4179.png`)
- **Heading**: `"A little about you"` & subtitle `"Let's start with your name and birthday."`
- **First Name**: `"First name"` label + rounded input box (`Anjali`).
- **Date of Birth**: `"Date of birth"` label + 3 side-by-side rounded cards (`Day` `14`, `Month` `06`, `Year` `1998`) with stacked muted label and bold numeric input.
- **Calculated Age Banner**: Soft grey rounded card (`#F4F4F5`) displaying `"You're 28 years old"` dynamically calculated from the entered date of birth.
- **Privacy Note**: Pink lock icon + `"Only your age appears on your profile—not your birthday."`
- **Footer Note**: `"naam is for adults aged 18 and over."` above `"Continue"` + `→`.

### Step `04 / 08` — Your Gender (`image_46ecb583.png`)
- **Heading**: `"Your gender"` & subtitle `"Choose what feels right for you."`
- **Selectable Cards**: `"Woman"`, `"Man"`, `"Non-binary"`.
  - Selected card has a `1.5px` `#F7196B` border, pink filled radio indicator, subtle horizontal divider, and `"＋ Add more detail"` link in hot pink.
  - Unselected cards have a `1px` `#E4E4E7` border and empty radio circle.
- **Visibility Toggle**: `"Show gender on my profile"` with a hot-pink iOS switch.
- **Footer Note**: `"You can change this anytime in your profile."` above `"Continue"` + `→`.

### Step `05 / 08` — Looking For (`image_ef7e5dd8.png`)
- **Heading**: `"Looking for..."` & subtitle `"Choose the connection you want."`
- **Selectable Cards**:
  - `"Open-minded relationship"`
  - `"Serious relationship"` (default selected, `#F7196B` border + pink radio indicator)
  - `"Casual"`
- **Footer Note**: `"You can change this anytime in your profile."` above `"Continue"` + `→`.

### Step `06 / 08` — Add Your Photos (`image_c1814247.png`)
- **Heading**: `"Add your photos"` & subtitle `"Tap to edit · Drag to reorder"`
- **3×2 Portrait Photo Grid** (6 slots, `3:4` aspect ratio, `18px` radius):
  - Pre-populated with 3 portrait photos (matching the screenshot's `"3 of 6 added"` state) and interactive add/remove/reorder support.
  - Filled slots display a top-right circular white pencil edit button; slot 1 includes a bottom-left dark frosted pill `"Main photo"`.
  - Empty slots (`#FBF8F9`) display a pink `+` icon and `"Add photo"` caption.
- **Counter & Tips Row**: Pink check-circle icon + `"3 of 6 added"` on the left, underlined pink `"Photo tips"` link on the right.
- **Guidance Row**: Pink image icon + `"Add 2–6 recent photos. A clear face photo first."`
- **CTA**: `"Continue with 3 photos"` (dynamically updates with photo count) + `→`.

### Step `07 / 08` — Find People Nearby (`image_a690a48c.png`)
- **Heading**: `"Find people nearby"` & subtitle `"Choose your city and distance."`
- **Current City Button**: Full-width pill button with pink border (`#F9C8D9`), pink GPS target icon, and pink label `"Use my current city"`.
- **City Dropdown**: `"Or choose your city"` label + rounded selector box with pin icon, `"Kochi, Kerala"` (selectable across Kerala/Malayali hub cities), and chevron.
- **Preferred Distance Card**: Soft grey card (`#F5F5F6`) with `"Preferred distance"` on the left, bold `"25 km"` on the right, interactive hot-pink range slider (`5 km` to `100 km`), and min/max captions.
- **Privacy Note**: Grey lock icon + `"Only your approximate city is shown. Your distance preference stays private."`
- **CTA**: `"Continue"` + `→`.

### Step `08 / 08` — Selfie Verification (`image_8eacebb1.png`)
- **Heading**: `"Let's verify it's you"` & subtitle `"A quick selfie helps confirm your identity."`
- **Guide Card**: Soft grey rounded card (`#F4F4F5`) with minimalist face-oval illustration on the left and `"Just you, clearly."` + `"Centre your whole face inside the guide."` on the right.
- **3 Checklist Items**:
  - Sun icon: `"Good light. Face clear and in focus."`
  - Person icon: `"No sunglasses, masks, filters or other people."`
  - Lock icon: `"We compare your selfie with your photos. It won't appear on your profile."`
- **Consent Checkbox**: Divider line + pink checked rounded square checkbox + `"I agree to naam using my selfie and profile photos for this identity check, as described in the Privacy Policy."` + underlined pink `"Read the Privacy Policy"`.
- **Footer Note**: `"Your phone will ask for camera access next."` above `"Capture selfie"` + `→`.

---

## 3. Files to Update
- `/frontend/public/assets/aistudio/` — Copy the onboarding reference assets so the Welcome hero photography is served cleanly by Next.js.
- `/frontend/src/pages/index.tsx` & `/frontend/src/styles/Home.module.css` — Implement the Welcome screen and 8-step onboarding wizard with pixel-accurate layout, typography, colors, and interactive state synced to the user's profile.
- `/mobile/lib/features/onboarding/onboarding_screen.dart` — Sync the Flutter onboarding implementation to match the exact 8-step flow.
