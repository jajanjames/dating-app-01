import type { NextPage } from "next";
import Head from "next/head";
import { useState, type FormEvent } from "react";
import styles from "@/styles/Home.module.css";

interface CandidateProfile {
  id: string;
  name: string;
  age: number;
  gender: "Women" | "Men";
  distanceKm: number;
  heightInches: number;
  heightLabel: string;
  occupation: string;
  education: string;
  zodiac: string;
  lifestyle: string;
  neighborhood: string;
  intention: string;
  status: string;
  faith: string;
  community: string;
  motherTongue: string;
  country: string;
  state: string;
  smoking: string;
  drug: string;
  bio: string;
  promptQuestion: string;
  promptAnswer: string;
  interests: string[];
  photos: string[];
  fallbackGradient: string;
  likesViewer: boolean;
  isOnline: boolean;
  lastSeenLabel: string;
  isRecent: boolean;
  isVerified: boolean;
  paidIntroMessage?: string;
}

interface ChatMessage {
  id: string;
  sender: "me" | "them";
  text: string;
  time: string;
}

interface MatchThread {
  id: string;
  profile: CandidateProfile;
  messages: ChatMessage[];
  unread?: boolean;
}



const CANDIDATE_CATALOG: CandidateProfile[] = [
  {
    id: "cand-aria",
    name: "Ananya",
    age: 27,
    gender: "Women",
    distanceKm: 3,
    heightInches: 66,
    heightLabel: "5'6\" (168 cm)",
    occupation: "Designer",
    education: "NID Ahmedabad",
    zodiac: "Libra",
    lifestyle: "Chai lover · Non-smoker",
    neighborhood: "Kochi",
    intention: "Long-term partner",
    status: "Single",
    faith: "Christian",
    community: "Syro-Malabar",
    motherTongue: "Malayalam",
    country: "India",
    state: "Kerala",
    smoking: "Non-Smoker",
    drug: "Never",
    bio: "Chai, good stories & a little spontaneity.",
    promptQuestion: "A Sunday well spent",
    promptAnswer:
      "Morning café hopping in Fort Kochi, browsing indie bookshops, and catching sunset by the water.",
    interests: ["Spatial Design", "Filter Coffee & Chai", "Indie Books", "Travel"],
    photos: [
      "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=1000&q=85",
    ],
    fallbackGradient: "#e4e4e7",
    likesViewer: true,
    isOnline: true,
    lastSeenLabel: "Online",
    isRecent: true,
    isVerified: true,
    paidIntroMessage:
      "Loved your taste in minimal architecture—chai this week?",
  },
  {
    id: "cand-julian",
    name: "Julian Mercer",
    age: 29,
    gender: "Men",
    distanceKm: 6,
    heightInches: 72,
    heightLabel: "6'0\" (183 cm)",
    occupation: "Architect",
    education: "Columbia GSAPP",
    zodiac: "Taurus",
    lifestyle: "Natural wine · Early riser",
    neighborhood: "Bengaluru",
    intention: "Long-term partner",
    status: "Single",
    faith: "Christian",
    community: "Malankara Orthodox",
    motherTongue: "Malayalam",
    country: "India",
    state: "Karnataka",
    smoking: "Non-Smoker",
    drug: "Occasionally",
    bio: "Restoring historic lofts and sketching coastal pavilions. Always up for a spontaneous gallery opening.",
    promptQuestion: "The quickest way to my heart",
    promptAnswer:
      "Warm cardamom buns and debating Brutalist vs. Nordic minimalism over pour-over coffee.",
    interests: ["Architecture", "Leica M6", "Sourdough", "Jazz Vinyl"],
    photos: [
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=1000&q=85",
    ],
    fallbackGradient: "#e4e4e7",
    likesViewer: true,
    isOnline: true,
    lastSeenLabel: "Online",
    isRecent: true,
    isVerified: true,
    paidIntroMessage:
      "I know a hidden courtyard bakery in Indiranagar you need to see.",
  },
  {
    id: "cand-elena",
    name: "Elena Rostova",
    age: 25,
    gender: "Women",
    distanceKm: 9,
    heightInches: 66,
    heightLabel: "5'6\" (168 cm)",
    occupation: "Botanical Perfumer",
    education: "Parsons",
    zodiac: "Pisces",
    lifestyle: "Matcha ritual · Dog lover",
    neighborhood: "Trivandrum",
    intention: "Intention-driven dating",
    status: "Single",
    faith: "Christian",
    community: "Marthoma",
    motherTongue: "Malayalam",
    country: "India",
    state: "Kerala",
    smoking: "Non-Smoker",
    drug: "Never",
    bio: "Formulating small-batch cedar and bergamot scents. Looking for someone to split seasonal tasting menus with.",
    promptQuestion: "First date wish list",
    promptAnswer:
      "Browsing rare art books at an indie shop followed by matcha lattes in a hidden courtyard.",
    interests: ["Olfaction", "Art Books", "Ceramics", "Matcha"],
    photos: [
      "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=1000&q=85",
    ],
    fallbackGradient: "#e4e4e7",
    likesViewer: true,
    isOnline: false,
    lastSeenLabel: "Seen 1h ago",
    isRecent: true,
    isVerified: false,
  },
  {
    id: "cand-mateo",
    name: "Mateo Silva",
    age: 28,
    gender: "Men",
    distanceKm: 15,
    heightInches: 71,
    heightLabel: "5'11\" (180 cm)",
    occupation: "Film Composer",
    education: "Juilliard",
    zodiac: "Scorpio",
    lifestyle: "Vinyl collector · Ocean swimmer",
    neighborhood: "Chennai",
    intention: "Long-term partner",
    status: "Single",
    faith: "Christian",
    community: "Roman Catholic",
    motherTongue: "English",
    country: "India",
    state: "Tamil Nadu",
    smoking: "Non-Smoker",
    drug: "Socially",
    bio: "Scoring independent cinema on analog synthesizers. Happiest near the ocean or at a late-night listening bar.",
    promptQuestion: "We will get along if",
    promptAnswer:
      "You stay through the end credits just to hear the closing orchestral score.",
    interests: ["Film Scoring", "Modular Synths", "Surfing", "35mm Film"],
    photos: [
      "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=1000&q=85",
    ],
    fallbackGradient: "#e4e4e7",
    likesViewer: true,
    isOnline: true,
    lastSeenLabel: "Online",
    isRecent: false,
    isVerified: true,
    paidIntroMessage:
      "Scoring a new short film tonight—what soundtrack never gets old for you?",
  },
  {
    id: "cand-claire",
    name: "Claire Dubois",
    age: 26,
    gender: "Women",
    distanceKm: 5,
    heightInches: 65,
    heightLabel: "5'5\" (166 cm)",
    occupation: "Ceramicist",
    education: "Central Saint Martins",
    zodiac: "Virgo",
    lifestyle: "Tea house regular · Cyclist",
    neighborhood: "Kottayam",
    intention: "Long-term partner",
    status: "Single",
    faith: "Christian",
    community: "Jacobite",
    motherTongue: "Malayalam",
    country: "India",
    state: "Kerala",
    smoking: "Non-Smoker",
    drug: "Never",
    bio: "Throwing stoneware bowls in my sunlit studio and hosting candlelit dinner parties for friends.",
    promptQuestion: "My simple pleasure",
    promptAnswer: "Warm sourdough with cultured butter right out of the oven.",
    interests: ["Ceramics", "Dinner Parties", "Cycling", "Modernist Design"],
    photos: [
      "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=1000&q=85",
    ],
    fallbackGradient: "#e4e4e7",
    likesViewer: false,
    isOnline: false,
    lastSeenLabel: "Seen 1d ago",
    isRecent: true,
    isVerified: true,
  },
  {
    id: "cand-soren",
    name: "Soren Lindqvist",
    age: 29,
    gender: "Men",
    distanceKm: 11,
    heightInches: 73,
    heightLabel: "6'1\" (185 cm)",
    occupation: "Industrial Designer",
    education: "Konstfack Stockholm",
    zodiac: "Aquarius",
    lifestyle: "Nordic sauna · Pour-over coffee",
    neighborhood: "Mumbai",
    intention: "Intention-driven dating",
    status: "Single",
    faith: "Christian",
    community: "Latin Catholic",
    motherTongue: "English",
    country: "India",
    state: "Maharashtra",
    smoking: "Socially",
    drug: "Cannabis",
    bio: "Obsessed with tactile aluminum, Dieter Rams radios, and weekend hikes in the hills.",
    promptQuestion: "Best travel story",
    promptAnswer: "Taking the night train to Lapland to sketch under the aurora.",
    interests: ["Industrial Design", "Trail Running", "Pour-Over", "Sauna"],
    photos: [
      "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=1000&q=85",
      "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=1000&q=85",
    ],
    fallbackGradient: "#e4e4e7",
    likesViewer: true,
    isOnline: false,
    lastSeenLabel: "Seen 2d ago",
    isRecent: false,
    isVerified: false,
  },
];

const SUBSCRIPTION_TIERS = [
  {
    id: "premium",
    title: "Premium",
    badge: "Essential",
    price: "₹499/mo",
    variant: "light" as const,
    perk: "Send unlimited daily likes and rewind accidental passes anytime.",
    features: [
      "Unlimited daily Likes & Rewinds",
      "Full Community, Faith & City filters",
      "Ad-free discovery experience",
    ],
  },
  {
    id: "premium_plus",
    title: "Premium+",
    badge: "Most Popular",
    price: "₹899/mo",
    variant: "rose" as const,
    perk: "Unlock everyone who liked you + 3x profile boost in your city.",
    features: [
      "See everyone who already Liked you",
      "5 free Direct Comments every week",
      "3× Profile Boost in your city weekly",
    ],
  },
  {
    id: "ultra",
    title: "Ultra",
    badge: "VIP Access",
    price: "₹1,499/mo",
    variant: "dark" as const,
    perk: "Priority VIP placement, unlimited comments, and curated weekly introductions.",
    features: [
      "Priority #1 placement in Discover & Likes",
      "Unlimited Direct Comments & Super-Stars",
      "Curated weekly VIP introductions",
    ],
  },
];

const LuxeCrownIcon = ({ size = 22 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="currentColor"
  >
    <path d="M3 18h18v2H3v-2zm0-2L5 7l5 4 2-6 2 6 5-4 2 9H3z" />
  </svg>
);

const ChevronRightIcon = ({ size = 18 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="m9 18 6-6-6-6" />
  </svg>
);

const ChevronLeftIcon = ({ size = 20 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.3"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="m15 18-6-6 6-6" />
  </svg>
);

const TWITTER_BURST_PARTICLES = [
  { tx: "0px", ty: "-42px", color: "#ff1f6d" },
  { tx: "30px", ty: "-30px", color: "#fb7185" },
  { tx: "42px", ty: "0px", color: "#f43f5e" },
  { tx: "30px", ty: "30px", color: "#f59e0b" },
  { tx: "0px", ty: "42px", color: "#ff1f6d" },
  { tx: "-30px", ty: "30px", color: "#ec4899" },
  { tx: "-42px", ty: "0px", color: "#f43f5e" },
  { tx: "-30px", ty: "-30px", color: "#fbbf24" },
];

const EXTRA_PORTRAIT_PRESETS = [
  "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=900&q=80",
];

type ActiveTab = "discover" | "matches" | "messages" | "profile";
type MatchFilterMode =
  | "all"
  | "recent"
  | "online"
  | "nearby"
  | "verified"
  | "likes_locked";
type ProfileSubPage =
  | "edit_profile"
  | "your_likes"
  | "recent_passes"
  | "safety_tips"
  | "help_center"
  | null;

function formatInchesToFeetLabel(inches: number): string {
  const feet = Math.floor(inches / 12);
  const rem = inches % 12;
  return `${feet}'${rem}"`;
}

/* Vector Icons */
const SoftHeartIcon = ({ size = 22 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 20.4c-.3 0-.6-.1-.8-.3-3.6-3.1-7.7-6.8-7.7-11.2 0-3.1 2.4-5.4 5.4-5.4 1.7 0 3.1.8 4.1 2.1 1-1.3 2.4-2.1 4.1-2.1 3 0 5.4 2.3 5.4 5.4 0 4.4-4.1 8.1-7.7 11.2-.2.2-.5.3-.8.3z" />
  </svg>
);

const HeartOutlineIcon = ({ size = 22 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
  </svg>
);

const SoftFilterIcon = ({ size = 20 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.1"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <line x1="4" y1="6" x2="10" y2="6" />
    <line x1="14" y1="6" x2="20" y2="6" />
    <line x1="12" y1="3.5" x2="12" y2="8.5" />
    <line x1="4" y1="12" x2="14" y2="12" />
    <line x1="18" y1="12" x2="20" y2="12" />
    <line x1="16" y1="9.5" x2="16" y2="14.5" />
    <line x1="4" y1="18" x2="8" y2="18" />
    <line x1="12" y1="18" x2="20" y2="18" />
    <line x1="10" y1="15.5" x2="10" y2="20.5" />
  </svg>
);

const RecentPassesBoxIcon = ({ size = 21 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <rect x="3" y="3" width="18" height="18" rx="4" />
    <path d="M16 12H8" />
    <path d="m11 9-3 3 3 3" />
  </svg>
);

const SafetyShieldIcon = ({ size = 21 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    <path d="m9 12 2 2 4-4" />
  </svg>
);

const HelpCircleIcon = ({ size = 21 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <circle cx="12" cy="12" r="9.5" />
    <path d="M9.1 9a3 3 0 0 1 5.8 1c0 2-3 2.5-3 4" />
    <circle cx="12" cy="17.2" r="0.8" fill="currentColor" />
  </svg>
);

const EditPencilIcon = ({ size = 16 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.1"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M17 3a2.83 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z" />
  </svg>
);

const ChevronDownIcon = ({ size = 22 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.3"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="m6 9 6 6 6-6" />
  </svg>
);

const SoftRewindIcon = ({ size = 20 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M3 10h11a5 5 0 0 1 0 10H9" />
    <path d="M7 6 3 10l4 4" />
  </svg>
);

const SoftCloseIcon = ({ size = 22 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.4"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M17 7 7 17" />
    <path d="m7 7 10 10" />
  </svg>
);

const SoftChatIcon = ({ size = 21 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.1"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M21 11.5a8.4 8.4 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.4 8.4 0 0 1-3.8-.9L3 21l1.9-5.7a8.4 8.4 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.4 8.4 0 0 1 3.8-.9h.5a8.5 8.5 0 0 1 8 8v.5z" />
  </svg>
);

const SoftStarIcon = ({ size = 22 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <polygon points="12 2.5 14.9 8.4 21.4 9.3 16.7 13.9 17.8 20.4 12 17.3 6.2 20.4 7.3 13.9 2.6 9.3 9.1 8.4 12 2.5" />
  </svg>
);

const SoftVerifiedBadgeIcon = ({ size = 16 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 2 14.8 4.2 18.3 3.7 19.6 7 22.5 9.1 21.3 12.5 22.5 15.9 19.6 18 18.3 21.3 14.8 20.8 12 23 9.2 20.8 5.7 21.3 4.4 18 1.5 15.9 2.7 12.5 1.5 9.1 4.4 7 5.7 3.7 9.2 4.2 12 2zm-1.2 13.6 5.6-5.6-1.4-1.4-4.2 4.2-2.1-2.1-1.4 1.4 3.5 3.5z" />
  </svg>
);

const SoftGridIcon = ({ size = 20 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.1"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <rect x="3" y="3" width="7.5" height="7.5" rx="2.5" />
    <rect x="13.5" y="3" width="7.5" height="7.5" rx="2.5" />
    <rect x="3" y="13.5" width="7.5" height="7.5" rx="2.5" />
    <rect x="13.5" y="13.5" width="7.5" height="7.5" rx="2.5" />
  </svg>
);

const SoftCompassIcon = ({ size = 20 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <circle cx="12" cy="12" r="9.5" />
    <polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76" />
  </svg>
);

const SoftUserIcon = ({ size = 20 }: { size?: number }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.1"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <circle cx="12" cy="8" r="4" />
    <path d="M5 20c1.5-3.5 4.2-5 7-5s5.5 1.5 7 5" />
  </svg>
);

const FILTER_ACCORDION_SECTIONS: {
  key: string;
  label: string;
  options: string[];
}[] = [
  {
    key: "status",
    label: "Status",
    options: ["Any", "Single", "Divorced", "Widowed", "Separated"],
  },
  {
    key: "faith",
    label: "Faith",
    options: ["Any", "Christian", "Hindu", "Muslim", "Spiritual"],
  },
  {
    key: "community",
    label: "Community",
    options: [
      "Any",
      "Syro-Malabar",
      "Malankara Orthodox",
      "Marthoma",
      "Roman Catholic",
      "Jacobite",
      "Latin Catholic",
    ],
  },
  {
    key: "motherTongue",
    label: "Mother Tongue",
    options: [
      "Any",
      "Malayalam",
      "English",
      "Tamil",
      "Hindi",
      "Kannada",
      "Telugu",
    ],
  },
  {
    key: "country",
    label: "Country",
    options: [
      "Any",
      "India",
      "United States",
      "United Kingdom",
      "UAE",
      "Canada",
      "Australia",
    ],
  },
  {
    key: "state",
    label: "State",
    options: [
      "Any",
      "Kerala",
      "Karnataka",
      "Tamil Nadu",
      "Maharashtra",
      "Delhi NCR",
    ],
  },
  {
    key: "smoking",
    label: "Smoking",
    options: ["Any", "Non-Smoker", "Socially", "Regular", "Trying to Quit"],
  },
  {
    key: "drug",
    label: "Drug",
    options: [
      "Any",
      "Never",
      "Occasionally",
      "Socially",
      "Cannabis",
      "420 Friendly",
    ],
  },
  {
    key: "gender",
    label: "Interested In",
    options: ["Everyone", "Women", "Men"],
  },
];

const Home: NextPage = () => {
  const [activeTab, setActiveTab] = useState<ActiveTab>("discover");
  const [isFilterSheetOpen, setIsFilterSheetOpen] = useState(false);

  // Redesigned Filter State matching Image 1 (Age 18-29, Height 4'0"-8'0", Sort By Activity, and Accordion rows)
  const [minAge, setMinAge] = useState<number>(18);
  const [maxAge, setMaxAge] = useState<number>(29);
  const [minHeightInches, setMinHeightInches] = useState<number>(48); // 4'0"
  const [maxHeightInches, setMaxHeightInches] = useState<number>(96); // 8'0"
  const [sortByActivity, setSortByActivity] = useState<boolean>(false);
  const [filterSelections, setFilterSelections] = useState<
    Record<string, string>
  >({
    status: "Any",
    faith: "Any",
    community: "Any",
    motherTongue: "Any",
    country: "Any",
    state: "Any",
    smoking: "Any",
    drug: "Any",
    gender: "Everyone",
  });
  const [expandedPrefKey, setExpandedPrefKey] = useState<string | null>(null);

  // Discovery Deck, Liked & Passed Profiles State
  const [swipedIds, setSwipedIds] = useState<string[]>([]);
  const [likedIds, setLikedIds] = useState<string[]>([
    "cand-aria",
    "cand-julian",
  ]);
  const [passedIds, setPassedIds] = useState<string[]>(["cand-soren"]);
  const [photoIdx, setPhotoIdx] = useState<number>(0);
  const [swipeAnim, setSwipeAnim] = useState<
    "pass" | "like" | "super" | "rewind" | null
  >(null);

  // Full-Screen Normal Page States (Profile Detail Page & Dedicated Message Page)
  const [fullScreenProfile, setFullScreenProfile] =
    useState<CandidateProfile | null>(null);
  const [fullScreenChatThread, setFullScreenChatThread] =
    useState<MatchThread | null>(null);

  // Floating Quick-Message Sheet over Discovery
  const [quickMsgCandidate, setQuickMsgCandidate] =
    useState<CandidateProfile | null>(null);
  const [quickMsgText, setQuickMsgText] = useState<string>("");

  // Matches Grid Filter Mode
  const [matchFilter, setMatchFilter] = useState<MatchFilterMode>("all");

  // Messages Inbox State
  const [threads, setThreads] = useState<MatchThread[]>([
    {
      id: "thread-aria",
      profile: CANDIDATE_CATALOG[0],
      unread: true,
      messages: [
        {
          id: "m-1",
          sender: "them",
          text: "Hey! Your prompt about specialty coffee caught my eye—what is your go-to roast?",
          time: "2:14 PM",
        },
      ],
    },
    {
      id: "thread-julian",
      profile: CANDIDATE_CATALOG[1],
      unread: true,
      messages: [
        {
          id: "m-2",
          sender: "them",
          text: "Are you free this Sunday for the new architecture exhibition?",
          time: "1:05 PM",
        },
      ],
    },
    {
      id: "thread-elena",
      profile: CANDIDATE_CATALOG[2],
      unread: false,
      messages: [
        {
          id: "m-3",
          sender: "them",
          text: "That hidden bookshop is my favorite rainy-day spot.",
          time: "Yesterday",
        },
      ],
    },
  ]);
  const [draftMessage, setDraftMessage] = useState<string>("");

  // Current User Profile State (Matches Images 2 & 3: "aria", 29% completion arc, Concierge & Comments, Settings, Love Stories)
  const [myPhotos, setMyPhotos] = useState<string[]>([
    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=900&q=85",
    "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80",
  ]);
  const [isViewerVerified, setIsViewerVerified] = useState<boolean>(true);
  const [userName, setUserName] = useState<string>("aria");
  const [userAge, setUserAge] = useState<number>(26);
  const [userPhone, setUserPhone] = useState<string>("+91 98470 51209");
  const [userOccupation, setUserOccupation] =
    useState<string>("Spatial Designer");
  const [userEducation, setUserEducation] = useState<string>("NID Ahmedabad");
  const [userNeighborhood, setUserNeighborhood] =
    useState<string>("Kochi, Kerala");
  const [userBio, setUserBio] = useState<string>(
    "Designing warm minimal spaces, collecting indie photobooks, and brewing filter coffee."
  );
  const [userPromptAnswer, setUserPromptAnswer] = useState<string>(
    "Morning gallery walk, fresh flowers, and cooking pasta with acoustic records."
  );

  // Subscription & Comments Interactive State
  const [conciergeSlideIdx, setConciergeSlideIdx] = useState<number>(1);
  const [activePlanModal, setActivePlanModal] = useState<
    "concierge" | "comments" | null
  >(null);
  const [commentCredits, setCommentCredits] = useState<number>(12);
  const [isConciergeActive, setIsConciergeActive] = useState<boolean>(false);

  // Profile Dedicated Sub-Pages
  const [profileSubPage, setProfileSubPage] = useState<ProfileSubPage>(null);
  const [supportTicketText, setSupportTicketText] = useState<string>("");
  const [statusBanner, setStatusBanner] = useState<string | null>(null);

  // Calculate dynamic completion percentage (starts at 29% with 2 photos, increases as photos/fields are added)
  const baseCompletion =
    myPhotos.length === 2
      ? 29
      : Math.min(
          100,
          Math.round(
            15 +
              myPhotos.length * 10 +
              (isViewerVerified ? 14 : 0) +
              (userBio.trim().length > 10 ? 10 : 0)
          )
        );

  const visibleDeck = CANDIDATE_CATALOG.filter((c) => {
    if (swipedIds.includes(c.id)) return false;
    if (
      filterSelections.gender !== "Everyone" &&
      c.gender !== filterSelections.gender
    ) {
      return false;
    }
    if (c.age < minAge || c.age > maxAge) return false;
    if (c.heightInches < minHeightInches || c.heightInches > maxHeightInches) {
      return false;
    }
    if (
      filterSelections.status !== "Any" &&
      c.status !== filterSelections.status
    ) {
      return false;
    }
    if (
      filterSelections.faith !== "Any" &&
      c.faith !== filterSelections.faith
    ) {
      return false;
    }
    if (
      filterSelections.community !== "Any" &&
      c.community !== filterSelections.community
    ) {
      return false;
    }
    if (
      filterSelections.motherTongue !== "Any" &&
      c.motherTongue !== filterSelections.motherTongue
    ) {
      return false;
    }
    if (
      filterSelections.country !== "Any" &&
      c.country !== filterSelections.country
    ) {
      return false;
    }
    if (
      filterSelections.state !== "Any" &&
      c.state !== filterSelections.state
    ) {
      return false;
    }
    if (
      filterSelections.smoking !== "Any" &&
      c.smoking !== filterSelections.smoking
    ) {
      return false;
    }
    if (
      filterSelections.drug !== "Any" &&
      c.drug !== filterSelections.drug
    ) {
      return false;
    }
    return true;
  }).sort((a, b) => {
    if (!sortByActivity) return 0;
    return Number(b.isOnline) - Number(a.isOnline);
  });

  const currentCandidate = visibleDeck[0] ?? null;

  const filteredMatchesGrid = CANDIDATE_CATALOG.filter((c) => {
    if (matchFilter === "recent") return c.isRecent;
    if (matchFilter === "online") return c.isOnline;
    if (matchFilter === "nearby") return c.distanceKm <= 8;
    if (matchFilter === "verified") return c.isVerified;
    return true;
  });

  const paidPriorityIntros = CANDIDATE_CATALOG.filter((c) =>
    Boolean(c.paidIntroMessage)
  );

  const likedProfilesList = CANDIDATE_CATALOG.filter((c) =>
    likedIds.includes(c.id)
  );
  const passedProfilesList = CANDIDATE_CATALOG.filter((c) =>
    passedIds.includes(c.id)
  );

  const showToast = (msg: string) => {
    setStatusBanner(msg);
    setTimeout(() => setStatusBanner(null), 2200);
  };

  const handleSwipeAction = (action: "pass" | "like" | "super") => {
    if (!currentCandidate || swipeAnim) return;
    const target = currentCandidate;
    setSwipeAnim(action);

    setTimeout(() => {
      setPhotoIdx(0);
      setSwipedIds((prev) => [...prev, target.id]);

      if (action === "pass") {
        setPassedIds((prev) =>
          prev.includes(target.id) ? prev : [target.id, ...prev]
        );
      } else {
        setLikedIds((prev) =>
          prev.includes(target.id) ? prev : [target.id, ...prev]
        );
      }
      setSwipeAnim(null);
    }, 340);
  };

  const handleRewind = () => {
    if (swipedIds.length === 0 || swipeAnim) return;
    setSwipeAnim("rewind");
    setTimeout(() => {
      setPhotoIdx(0);
      setSwipedIds((prev) => prev.slice(0, -1));
      setSwipeAnim(null);
    }, 300);
  };

  const handleResetFilters = () => {
    setPhotoIdx(0);
    setSwipedIds([]);
    setMinAge(18);
    setMaxAge(29);
    setMinHeightInches(48);
    setMaxHeightInches(96);
    setSortByActivity(false);
    setFilterSelections({
      status: "Any",
      faith: "Any",
      community: "Any",
      motherTongue: "Any",
      country: "Any",
      state: "Any",
      smoking: "Any",
      drug: "Any",
      gender: "Everyone",
    });
    setExpandedPrefKey(null);
  };

  const handleSendQuickMessage = (e: FormEvent) => {
    e.preventDefault();
    if (!quickMsgCandidate || !quickMsgText.trim()) return;
    const text = quickMsgText.trim();
    const target = quickMsgCandidate;

    const newMsg: ChatMessage = {
      id: `msg-${Date.now()}`,
      sender: "me",
      text,
      time: "Just now",
    };

    setThreads((prev) => {
      const existing = prev.find((t) => t.profile.id === target.id);
      if (existing) {
        return [
          {
            ...existing,
            unread: false,
            messages: [...existing.messages, newMsg],
          },
          ...prev.filter((t) => t.profile.id !== target.id),
        ];
      }
      return [
        {
          id: `thread-${target.id}`,
          profile: target,
          unread: false,
          messages: [newMsg],
        },
        ...prev,
      ];
    });

    if (commentCredits > 0) {
      setCommentCredits((c) => c - 1);
    }
    setQuickMsgText("");
    setQuickMsgCandidate(null);
    showToast(`Comment delivered to ${target.name}`);
  };

  const handleSendChatReply = (e: FormEvent) => {
    e.preventDefault();
    if (!fullScreenChatThread || !draftMessage.trim()) return;
    const text = draftMessage.trim();
    setDraftMessage("");
    const newMsg: ChatMessage = {
      id: `msg-${Date.now()}`,
      sender: "me",
      text,
      time: "Just now",
    };

    setThreads((prev) =>
      prev.map((t) =>
        t.id === fullScreenChatThread.id
          ? { ...t, unread: false, messages: [...t.messages, newMsg] }
          : t
      )
    );
    setFullScreenChatThread((prev) =>
      prev ? { ...prev, messages: [...prev.messages, newMsg] } : null
    );
  };

  const handleAddOrSwapPhoto = (slotIndex: number) => {
    if (slotIndex < myPhotos.length) {
      const nextPreset =
        EXTRA_PORTRAIT_PRESETS[
          (slotIndex + myPhotos.length) % EXTRA_PORTRAIT_PRESETS.length
        ];
      setMyPhotos((prev) =>
        prev.map((url, idx) => (idx === slotIndex ? nextPreset : url))
      );
      showToast("Updated profile photo");
    } else {
      const nextPreset =
        EXTRA_PORTRAIT_PRESETS[myPhotos.length % EXTRA_PORTRAIT_PRESETS.length];
      setMyPhotos((prev) => [...prev, nextPreset]);
      showToast("Added new profile photo");
    }
  };

  const handleRemovePhoto = (slotIndex: number) => {
    if (myPhotos.length <= 1) return;
    setMyPhotos((prev) => prev.filter((_, idx) => idx !== slotIndex));
  };

  const activePhotoUrl =
    currentCandidate?.photos[
      photoIdx % (currentCandidate?.photos.length || 1)
    ] ?? "";

  const activeSubscriptionTier =
    SUBSCRIPTION_TIERS[conciergeSlideIdx % SUBSCRIPTION_TIERS.length];

  const unreadThreadCount = threads.filter((t) => t.unread).length;

  return (
    <>
      <Head>
        <title>jdate — Intentional Dating</title>
        <meta
          name="description"
          content="JDATE modern intentional dating experience."
        />
      </Head>

      <div className={`${styles.viewportRoot} ${styles.pearlTheme}`}>
        <div className={styles.mobileCanvas}>
          {/* FULL-SCREEN NORMAL PAGE 1: Candidate Full Profile Detail Page */}
          {fullScreenProfile ? (
            <section className={styles.fullPageScreen}>
              <header className={styles.fullPageTopBar}>
                <div className={styles.fullPageTitleGroup}>
                  <h1 className={styles.viewHeader}>
                    {fullScreenProfile.name}, {fullScreenProfile.age}
                  </h1>
                  <span
                    className={styles.filterChip}
                    style={{
                      minHeight: "28px",
                      padding: "0 10px",
                      fontSize: "11px",
                      color: fullScreenProfile.isVerified
                        ? "#F93666"
                        : "var(--lg-muted)",
                    }}
                  >
                    {fullScreenProfile.isVerified && (
                      <SoftVerifiedBadgeIcon size={14} />
                    )}
                    <span>
                      {fullScreenProfile.isVerified ? "Verified" : "Unverified"}
                    </span>
                  </span>
                </div>

                <button
                  type="button"
                  className={styles.topFilterOrb}
                  onClick={() => setFullScreenProfile(null)}
                  aria-label="Close profile and return"
                  title="Close"
                >
                  <SoftCloseIcon size={19} />
                </button>
              </header>

              {/* 3-Step Interleaved Photo & Story Sequence */}
              <div className={styles.detailSequenceContainer}>
                {/* SEQUENCE 1: Photo 1 + Name, Job Role, What They Do & Location */}
                <div className={styles.detailSequenceStep}>
                  <div
                    className={styles.detailGalleryPhoto}
                    style={{
                      backgroundImage: `url(${fullScreenProfile.photos[0]})`,
                    }}
                  />
                  <div className={styles.sequenceInfoCard}>
                    <h2 className={styles.sequenceNameTitle}>
                      <span>
                        {fullScreenProfile.name}, {fullScreenProfile.age}
                      </span>
                      {fullScreenProfile.isVerified && (
                        <span style={{ color: "#F93666", display: "flex" }}>
                          <SoftVerifiedBadgeIcon size={20} />
                        </span>
                      )}
                    </h2>
                    <div className={styles.sequenceRoleRow}>
                      {fullScreenProfile.occupation} · {fullScreenProfile.education}
                    </div>
                    <div className={styles.sequenceLocationRow}>
                      {fullScreenProfile.neighborhood}, {fullScreenProfile.state} ·{" "}
                      {fullScreenProfile.distanceKm} km away
                    </div>
                    <p className={styles.sequenceBodyText}>
                      {fullScreenProfile.bio}
                    </p>
                  </div>
                </div>

                {/* SEQUENCE 2: Photo 2 + Description & Something About Them */}
                <div className={styles.detailSequenceStep}>
                  <div
                    className={styles.detailGalleryPhoto}
                    style={{
                      backgroundImage: `url(${
                        fullScreenProfile.photos[1] ?? fullScreenProfile.photos[0]
                      })`,
                    }}
                  />
                  <div className={styles.sequenceInfoCard}>
                    <div className={styles.paidBadgeText}>
                      {fullScreenProfile.promptQuestion}
                    </div>
                    <p
                      style={{
                        fontSize: "17px",
                        fontWeight: 700,
                        lineHeight: 1.45,
                        color: "#09090b",
                        margin: 0,
                      }}
                    >
                      &ldquo;{fullScreenProfile.promptAnswer}&rdquo;
                    </p>
                    <p className={styles.sequenceBodyText}>
                      Looking for {fullScreenProfile.intention.toLowerCase()} ·{" "}
                      {fullScreenProfile.lifestyle}
                    </p>
                  </div>
                </div>

                {/* SEQUENCE 3: Photo 3 + Description, Background & Interests */}
                <div className={styles.detailSequenceStep}>
                  <div
                    className={styles.detailGalleryPhoto}
                    style={{
                      backgroundImage: `url(${
                        fullScreenProfile.photos[2] ?? fullScreenProfile.photos[0]
                      })`,
                    }}
                  />
                  <div className={styles.sequenceInfoCard}>
                    <div className={styles.paidBadgeText}>
                      More About {fullScreenProfile.name}
                    </div>
                    <p className={styles.sequenceBodyText}>
                      {fullScreenProfile.faith} ({fullScreenProfile.community}) ·
                      Speaks {fullScreenProfile.motherTongue} ·{" "}
                      {fullScreenProfile.heightLabel} · {fullScreenProfile.status} ·{" "}
                      {fullScreenProfile.smoking}
                    </p>
                    <div className={styles.sequenceTagRow}>
                      {fullScreenProfile.interests.map((interest) => (
                        <span
                          key={interest}
                          className={styles.sequencePillTag}
                        >
                          {interest}
                        </span>
                      ))}
                    </div>

                    <div
                      style={{
                        display: "flex",
                        gap: "10px",
                        marginTop: "8px",
                      }}
                    >
                      <button
                        type="button"
                        className={styles.primaryCapsuleBtn}
                        style={{ flex: 1 }}
                        onClick={() => {
                          const person = fullScreenProfile;
                          setFullScreenProfile(null);
                          setQuickMsgCandidate(person);
                        }}
                      >
                        <SoftChatIcon size={18} />
                        <span>Send Comment to {fullScreenProfile.name}</span>
                      </button>
                      <button
                        type="button"
                        className={styles.topFilterOrb}
                        onClick={() => setFullScreenProfile(null)}
                        title="Close"
                      >
                        <SoftCloseIcon size={18} />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </section>
          ) : fullScreenChatThread ? (
            /* FULL-SCREEN NORMAL PAGE 2: Full-Fledged Dedicated Chat Conversation Screen (No Bottom Navigation Bar) */
            <section className={styles.fullChatScreen}>
              <header className={styles.fullChatHeader}>
                <button
                  type="button"
                  className={styles.fullChatBackBtn}
                  onClick={() => setFullScreenChatThread(null)}
                  aria-label="Back to conversations"
                  title="Back"
                >
                  <ChevronLeftIcon size={20} />
                </button>

                <button
                  type="button"
                  className={styles.fullChatPartnerBtn}
                  onClick={() =>
                    setFullScreenProfile(fullScreenChatThread.profile)
                  }
                  title={`View ${fullScreenChatThread.profile.name}'s profile`}
                >
                  <div className={styles.fullChatAvatarWrap}>
                    <div
                      className={styles.fullChatAvatar}
                      style={{
                        backgroundImage: `url(${fullScreenChatThread.profile.photos[0]})`,
                      }}
                    />
                    {fullScreenChatThread.profile.isOnline && (
                      <span className={styles.fullChatOnlineDot} />
                    )}
                  </div>

                  <div className={styles.fullChatPartnerMeta}>
                    <div className={styles.fullChatPartnerNameRow}>
                      <span>
                        {fullScreenChatThread.profile.name},{" "}
                        {fullScreenChatThread.profile.age}
                      </span>
                      {fullScreenChatThread.profile.isVerified && (
                        <span style={{ color: "#F93666", display: "flex" }}>
                          <SoftVerifiedBadgeIcon size={15} />
                        </span>
                      )}
                    </div>
                    <div className={styles.fullChatPresenceRow}>
                      <span
                        className={
                          fullScreenChatThread.profile.isOnline
                            ? styles.statusDotOnline
                            : styles.statusDotOffline
                        }
                        style={{
                          width: "6px",
                          height: "6px",
                          backgroundColor: fullScreenChatThread.profile.isOnline
                            ? "#22c55e"
                            : "#a1a1aa",
                          boxShadow: "none",
                        }}
                      />
                      <span>
                        {fullScreenChatThread.profile.lastSeenLabel} ·{" "}
                        {fullScreenChatThread.profile.neighborhood}
                      </span>
                    </div>
                  </div>
                </button>

                <button
                  type="button"
                  className={styles.fullChatProfilePill}
                  onClick={() =>
                    setFullScreenProfile(fullScreenChatThread.profile)
                  }
                >
                  Profile
                </button>
              </header>

              <div className={styles.fullChatStream}>
                <div className={styles.fullChatMatchBanner}>
                  Matched with {fullScreenChatThread.profile.name} ·{" "}
                  {fullScreenChatThread.profile.occupation} in{" "}
                  {fullScreenChatThread.profile.neighborhood}
                </div>

                {fullScreenChatThread.messages.map((m) => (
                  <div
                    key={m.id}
                    className={`${styles.msgGroup} ${
                      m.sender === "me"
                        ? styles.msgGroupMe
                        : styles.msgGroupThem
                    }`}
                  >
                    <div
                      className={
                        m.sender === "me"
                          ? styles.msgBubbleMe
                          : styles.msgBubbleThem
                      }
                    >
                      {m.text}
                    </div>
                    <span className={styles.msgTimeMeta}>
                      {m.time}
                      {m.sender === "me" ? " · Delivered" : ""}
                    </span>
                  </div>
                ))}
              </div>

              <div className={styles.fullChatIcebreakerStrip}>
                {[
                  `How is your week going in ${fullScreenChatThread.profile.neighborhood}?`,
                  "Coffee or chai this weekend?",
                  `Loved your prompt about "${fullScreenChatThread.profile.promptQuestion}"`,
                ].map((promptText) => (
                  <button
                    key={promptText}
                    type="button"
                    className={styles.fullChatIcebreakerPill}
                    onClick={() => setDraftMessage(promptText)}
                  >
                    {promptText}
                  </button>
                ))}
              </div>

              <form
                onSubmit={handleSendChatReply}
                className={styles.fullChatComposerBar}
              >
                <div className={styles.composerCapsule}>
                  <input
                    type="text"
                    className={styles.composerInput}
                    placeholder={`Message ${fullScreenChatThread.profile.name.split(" ")[0]}...`}
                    value={draftMessage}
                    onChange={(e) => setDraftMessage(e.target.value)}
                    autoFocus
                  />
                  <button
                    type="submit"
                    className={styles.sendOrbBtn}
                    disabled={!draftMessage.trim()}
                  >
                    Send
                  </button>
                </div>
              </form>
            </section>
          ) : (
            /* STANDARD 4-TAB MOBILE EXPERIENCE */
            <>
              {profileSubPage === null && (
                <header className={styles.floatingTopBar}>
                  <div className={styles.naamBrandWrap}>
                    <img
                      src="/assets/aistudio/image_cd469378.png"
                      alt="Naam"
                      className={styles.naamBrandLogo}
                    />
                  </div>

                  {activeTab === "discover" && (
                    <button
                      type="button"
                      className={styles.topFilterOrb}
                      onClick={() => setIsFilterSheetOpen(true)}
                      aria-label="Open Filter Preferences"
                      title="Filter Preferences"
                    >
                      <SoftFilterIcon size={19} />
                    </button>
                  )}
                </header>
              )}

              {statusBanner && (
                <div
                  className={styles.glassSurfaceCard}
                  style={{
                    padding: "10px 16px",
                    marginBottom: "6px",
                    textAlign: "center",
                    fontSize: "13px",
                    fontWeight: 700,
                    color: "#F93666",
                    borderColor: "rgba(249, 54, 102, 0.25)",
                  }}
                >
                  {statusBanner}
                </div>
              )}

              <main
                className={`${styles.stageContainer} ${
                  activeTab === "discover" ? styles.stageContainerNoScroll : ""
                }`}
              >
                {/* TAB 1: DISCOVER */}
                {activeTab === "discover" && (
                  <div className={styles.discoverFigmaStage}>
                    {currentCandidate ? (
                      <>
                        <article
                          className={`${styles.portraitCard} ${
                            swipeAnim === "like"
                              ? styles.portraitCardAnimLike
                              : swipeAnim === "pass"
                                ? styles.portraitCardAnimPass
                                : swipeAnim === "super"
                                  ? styles.portraitCardAnimSuper
                                  : swipeAnim === "rewind"
                                    ? styles.portraitCardAnimRewind
                                    : ""
                          }`}
                        >
                          <div
                            key={`${currentCandidate.id}-${photoIdx}`}
                            className={styles.portraitMediaLayer}
                            style={{
                              backgroundImage: `url(${activePhotoUrl})`,
                            }}
                          />
                          <div className={styles.portraitScrim} />

                          {swipeAnim && (
                            <div
                              className={`${styles.microActionBadge} ${
                                swipeAnim === "like"
                                  ? styles.microActionBadgeLike
                                  : swipeAnim === "super"
                                    ? styles.microActionBadgeSuper
                                    : styles.microActionBadgeNeutral
                              }`}
                            >
                              {swipeAnim === "like" && <SoftHeartIcon size={28} />}
                              {swipeAnim === "pass" && <SoftCloseIcon size={28} />}
                              {swipeAnim === "super" && <SoftStarIcon size={28} />}
                              {swipeAnim === "rewind" && <SoftRewindIcon size={26} />}
                            </div>
                          )}

                          <div className={styles.photoTapZones}>
                            <button
                              type="button"
                              className={styles.tapZoneBtn}
                              aria-label="Previous photo"
                              onClick={() =>
                                setPhotoIdx(
                                  (i) =>
                                    (i - 1 + currentCandidate.photos.length) %
                                    currentCandidate.photos.length
                                )
                              }
                            />
                            <button
                              type="button"
                              className={styles.tapZoneBtn}
                              aria-label="Open full profile page"
                              onClick={() =>
                                setFullScreenProfile(currentCandidate)
                              }
                            />
                            <button
                              type="button"
                              className={styles.tapZoneBtn}
                              aria-label="Next photo"
                              onClick={() =>
                                setPhotoIdx(
                                  (i) => (i + 1) % currentCandidate.photos.length
                                )
                              }
                            />
                          </div>

                          <div className={styles.portraitTopStack}>
                            <div className={styles.storyBarsRow}>
                              {currentCandidate.photos.map((_, idx) => (
                                <button
                                  key={idx}
                                  type="button"
                                  aria-label={`Photo ${idx + 1}`}
                                  className={`${styles.storySegment} ${
                                    idx ===
                                    photoIdx % currentCandidate.photos.length
                                      ? styles.storySegmentActive
                                      : ""
                                  }`}
                                  onClick={() => setPhotoIdx(idx)}
                                />
                              ))}
                            </div>

                            <div className={styles.topBadgesRow}>
                              <span className={styles.liquidGlassStatusBadge}>
                                <span
                                  className={
                                    currentCandidate.isOnline
                                      ? styles.statusDotOnline
                                      : styles.statusDotOffline
                                  }
                                />
                                <span>{currentCandidate.lastSeenLabel}</span>
                              </span>
                            </div>
                          </div>

                          <div className={styles.portraitBottomStack}>
                            <button
                              type="button"
                              className={styles.identityClickArea}
                              onClick={() =>
                                setFullScreenProfile(currentCandidate)
                              }
                            >
                              <div className={styles.candidateNameRow}>
                                <span className={styles.candidateName}>
                                  {currentCandidate.name}, {currentCandidate.age}
                                </span>
                                {currentCandidate.isVerified && (
                                  <span
                                    style={{ color: "#ffffff", display: "flex" }}
                                  >
                                    <SoftVerifiedBadgeIcon size={18} />
                                  </span>
                                )}
                              </div>
                              <p className={styles.candidateSubline}>
                                {currentCandidate.occupation} ·{" "}
                                {currentCandidate.neighborhood}
                              </p>
                              <p className={styles.candidateBioLine}>
                                {currentCandidate.bio}
                              </p>
                            </button>
                          </div>
                        </article>

                        {/* 5 Circular Action Buttons Below the Card with Twitter-Style Micro-Interactions */}
                        <div className={styles.discoverActionRow}>
                          <button
                            type="button"
                            className={`${styles.figmaCircleBtn} ${styles.figmaCircleBtnSmall} ${
                              swipeAnim === "rewind" ? styles.actionBtnPressed : ""
                            }`}
                            onClick={handleRewind}
                            disabled={swipedIds.length === 0}
                            aria-label="Reverse"
                            title="Reverse"
                          >
                            {swipeAnim === "rewind" && (
                              <span
                                className={`${styles.twitterRingWave} ${styles.twitterRingWaveNeutral}`}
                              />
                            )}
                            <span
                              className={
                                swipeAnim === "rewind" ? styles.neutralIconPop : ""
                              }
                            >
                              <SoftRewindIcon size={19} />
                            </span>
                          </button>

                          <button
                            type="button"
                            className={`${styles.figmaCircleBtn} ${
                              swipeAnim === "pass" ? styles.actionBtnPressed : ""
                            }`}
                            onClick={() => handleSwipeAction("pass")}
                            aria-label="Skip"
                            title="Skip"
                          >
                            {swipeAnim === "pass" && (
                              <span
                                className={`${styles.twitterRingWave} ${styles.twitterRingWaveNeutral}`}
                              />
                            )}
                            <span
                              className={
                                swipeAnim === "pass" ? styles.neutralIconPop : ""
                              }
                            >
                              <SoftCloseIcon size={22} />
                            </span>
                          </button>

                          <button
                            type="button"
                            className={`${styles.figmaHeartPrimaryBtn} ${
                              swipeAnim === "like" ? styles.actionBtnPressedHeart : ""
                            }`}
                            onClick={() => handleSwipeAction("like")}
                            aria-label="Like"
                            title="Like"
                          >
                            {swipeAnim === "like" && (
                              <span className={styles.twitterBurstWrap}>
                                <span className={styles.twitterRingWave} />
                                {TWITTER_BURST_PARTICLES.map((p, idx) => (
                                  <span
                                    key={idx}
                                    className={styles.twitterParticle}
                                    style={
                                      {
                                        "--tx": p.tx,
                                        "--ty": p.ty,
                                        "--pcolor": p.color,
                                      } as React.CSSProperties
                                    }
                                  />
                                ))}
                              </span>
                            )}
                            <span
                              className={
                                swipeAnim === "like" ? styles.heartIconPop : ""
                              }
                            >
                              {swipeAnim === "like" ? (
                                <SoftHeartIcon size={28} />
                              ) : (
                                <HeartOutlineIcon size={28} />
                              )}
                            </span>
                          </button>

                          <button
                            type="button"
                            className={`${styles.figmaCircleBtn} ${
                              swipeAnim === "super"
                                ? `${styles.actionBtnPressed} ${styles.actionBtnPressedStar}`
                                : ""
                            }`}
                            onClick={() => handleSwipeAction("super")}
                            aria-label="Star"
                            title="Star"
                          >
                            {swipeAnim === "super" && (
                              <span
                                className={`${styles.twitterRingWave} ${styles.twitterRingWaveGold}`}
                              />
                            )}
                            <span
                              className={
                                swipeAnim === "super" ? styles.starIconPop : ""
                              }
                            >
                              <SoftStarIcon size={21} />
                            </span>
                          </button>

                          <button
                            type="button"
                            className={`${styles.figmaCircleBtn} ${styles.figmaCircleBtnSmall}`}
                            onClick={() =>
                              setQuickMsgCandidate(currentCandidate)
                            }
                            aria-label="Message"
                            title="Message"
                          >
                            <SoftChatIcon size={19} />
                          </button>
                        </div>
                      </>
                    ) : (
                      <section className={styles.stateCard}>
                        <h1 className={styles.viewHeader}>
                          No Profiles Match Your Search
                        </h1>
                        <p className={styles.viewSubtext}>
                          Adjust your age, height, or community filters or reset your search preferences.
                        </p>
                        <button
                          type="button"
                          className={styles.primaryCapsuleBtn}
                          onClick={handleResetFilters}
                        >
                          Reset Search & Reload Deck
                        </button>
                      </section>
                    )}
                  </div>
                )}

                {/* TAB 2: MATCHES */}
                {activeTab === "matches" && (
                  <section className={styles.sectionContainer}>
                    <div>
                      <h1 className={styles.viewHeader}>Matches & Likes</h1>
                      <p className={styles.viewSubtext}>
                        Filter by Recent, Online, Verified, or tap any person to view their full profile.
                      </p>
                    </div>

                    <div className={styles.filterChipsScroll}>
                      {(
                        [
                          { id: "all", label: "All" },
                          { id: "recent", label: "Recent" },
                          { id: "online", label: "Online" },
                          { id: "nearby", label: "Nearby" },
                          { id: "verified", label: "Verified Only" },
                          { id: "likes_locked", label: "Liked You" },
                        ] as { id: MatchFilterMode; label: string }[]
                      ).map((chip) => (
                        <button
                          key={chip.id}
                          type="button"
                          className={`${styles.filterChip} ${
                            matchFilter === chip.id
                              ? styles.filterChipActive
                              : ""
                          }`}
                          onClick={() => setMatchFilter(chip.id)}
                        >
                          <span>{chip.label}</span>
                        </button>
                      ))}
                    </div>

                    <div className={styles.matchesGrid}>
                      {filteredMatchesGrid.map((person) => {
                        const isBlurred =
                          matchFilter === "likes_locked" && !isConciergeActive;
                        return (
                          <button
                            key={person.id}
                            type="button"
                            className={styles.matchGridCard}
                            style={
                              isBlurred
                                ? undefined
                                : {
                                    backgroundImage: `url(${person.photos[0]})`,
                                  }
                            }
                            onClick={() => {
                              if (isBlurred) {
                                setActivePlanModal("concierge");
                              } else {
                                setFullScreenProfile(person);
                              }
                            }}
                          >
                            {isBlurred && (
                              <div
                                className={styles.blurredCardMedia}
                                style={{
                                  backgroundImage: `url(${person.photos[0]})`,
                                }}
                              />
                            )}
                            <div className={styles.portraitScrim} />

                            <div className={styles.gridCardTopRow}>
                              <span className={styles.liquidGlassStatusBadge}>
                                <span
                                  className={
                                    person.isOnline
                                      ? styles.statusDotOnline
                                      : styles.statusDotOffline
                                  }
                                />
                                <span>{person.lastSeenLabel}</span>
                              </span>
                              <span className={styles.verifiedBadge}>
                                {person.isVerified && (
                                  <span
                                    style={{
                                      color: "#F93666",
                                      display: "flex",
                                    }}
                                  >
                                    <SoftVerifiedBadgeIcon size={12} />
                                  </span>
                                )}
                                <span>
                                  {person.isVerified
                                    ? "Verified"
                                    : "Unverified"}
                                </span>
                              </span>
                            </div>

                            <div className={styles.gridCardBottom}>
                              <div className={styles.gridCardName}>
                                <span>
                                  {isBlurred
                                    ? "Admirer Nearby"
                                    : `${person.name}, ${person.age}`}
                                </span>
                              </div>
                              <div className={styles.gridCardMeta}>
                                {person.occupation} · {person.neighborhood}
                              </div>
                            </div>
                          </button>
                        );
                      })}
                    </div>
                  </section>
                )}

                {/* TAB 3: MESSAGES (Compact New Matches Row + Flat Chat List) */}
                {activeTab === "messages" && (
                  <section className={styles.minimalChatsScreen}>
                    {/* Compact New Matches & Intros Row at Top */}
                    <div className={styles.compactMatchesSection}>
                      <div className={styles.compactSectionLabel}>
                        New Matches
                      </div>
                      <div className={styles.compactMatchesStrip}>
                        {CANDIDATE_CATALOG.slice(0, 5).map((person) => {
                          const hasIntro = Boolean(person.paidIntroMessage);
                          return (
                            <button
                              key={person.id}
                              type="button"
                              className={styles.compactMatchAvatarBtn}
                              onClick={() => {
                                const existing = threads.find(
                                  (t) => t.profile.id === person.id
                                );
                                if (existing) {
                                  setFullScreenChatThread(existing);
                                } else {
                                  const created: MatchThread = {
                                    id: `thread-${person.id}`,
                                    profile: person,
                                    messages: [
                                      {
                                        id: `paid-${person.id}`,
                                        sender: "them",
                                        text:
                                          person.paidIntroMessage ??
                                          "Matched with you on Naam",
                                        time: "Just now",
                                      },
                                    ],
                                  };
                                  setThreads((prev) => [created, ...prev]);
                                  setFullScreenChatThread(created);
                                }
                              }}
                            >
                              <div className={styles.compactMatchRing}>
                                <div
                                  className={styles.compactMatchImg}
                                  style={{
                                    backgroundImage: `url(${person.photos[0]})`,
                                  }}
                                />
                                {hasIntro && (
                                  <span className={styles.compactMatchDot} />
                                )}
                              </div>
                              <span className={styles.compactMatchName}>
                                {person.name.split(" ")[0]}
                              </span>
                            </button>
                          );
                        })}
                      </div>
                    </div>

                    {/* Flat Edge-to-Edge Chat List Below */}
                    <div className={styles.flatThreadsContainer}>
                      {threads.map((thread) => {
                        const lastMsg =
                          thread.messages[thread.messages.length - 1];
                        return (
                          <button
                            key={thread.id}
                            type="button"
                            className={styles.flatThreadRow}
                            onClick={() => setFullScreenChatThread(thread)}
                          >
                            <div
                              className={styles.flatThreadAvatar}
                              style={{
                                backgroundImage: `url(${thread.profile.photos[0]})`,
                              }}
                            />
                            <div className={styles.matchTextCol}>
                              <div className={styles.matchPartnerName}>
                                <span>
                                  {thread.profile.name.split(" ")[0]}
                                </span>
                                {thread.profile.isVerified && (
                                  <span
                                    style={{
                                      color: "#F93666",
                                      display: "flex",
                                    }}
                                  >
                                    <SoftVerifiedBadgeIcon size={14} />
                                  </span>
                                )}
                              </div>
                              <div
                                className={`${styles.matchSnippet} ${
                                  thread.unread ? styles.matchSnippetUnread : ""
                                }`}
                              >
                                {lastMsg
                                  ? lastMsg.text
                                  : "Tap to start chatting"}
                              </div>
                            </div>
                            <div className={styles.flatThreadMetaCol}>
                              <span className={styles.matchTime}>
                                {lastMsg?.time ?? "Now"}
                              </span>
                              {thread.unread && (
                                <span className={styles.unreadDotIndicator} />
                              )}
                            </div>
                          </button>
                        );
                      })}
                    </div>
                  </section>
                )}

                {/* TAB 4: PROFILE (Minimal Identity + Clean White/Rose Premium Card + 4 Settings Rows) */}
                {activeTab === "profile" && (
                  <>
                    {/* SUB-VIEW 1: Full Photo Grid & Personal Info Editor */}
                    {profileSubPage === "edit_profile" ? (
                      <section className={styles.fullPageScreen}>
                        <header className={styles.fullPageTopBar}>
                          <div>
                            <h1 className={styles.viewHeader}>
                              Edit Profile
                            </h1>
                          </div>
                          <button
                            type="button"
                            className={styles.topFilterOrb}
                            onClick={() => setProfileSubPage(null)}
                            aria-label="Back to Profile"
                          >
                            <SoftCloseIcon size={18} />
                          </button>
                        </header>

                        {/* 6-Slot Photo Grid Manager */}
                        <div className={styles.glassSurfaceCard}>
                          <div>
                            <h2 className={styles.viewHeader}>
                              Profile Photos ({myPhotos.length}/6)
                            </h2>
                            <p className={styles.viewSubtext}>
                              Tap any slot to add or swap a portrait. Adding more photos boosts your profile completion.
                            </p>
                          </div>

                          <div className={styles.photoManagerGrid}>
                            {[0, 1, 2, 3, 4, 5].map((slotIdx) => {
                              const url = myPhotos[slotIdx];
                              return (
                                <div
                                  key={slotIdx}
                                  className={`${styles.photoSlot} ${
                                    url ? styles.photoSlotFilled : ""
                                  }`}
                                  style={
                                    url
                                      ? { backgroundImage: `url(${url})` }
                                      : undefined
                                  }
                                  onClick={() => handleAddOrSwapPhoto(slotIdx)}
                                >
                                  {!url && (
                                    <span
                                      style={{
                                        fontSize: "12px",
                                        fontWeight: 700,
                                        color: "#F93666",
                                      }}
                                    >
                                      + Add
                                    </span>
                                  )}
                                  {url && (
                                    <button
                                      type="button"
                                      className={styles.photoSlotActionPill}
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        if (myPhotos.length > 1) {
                                          handleRemovePhoto(slotIdx);
                                        } else {
                                          handleAddOrSwapPhoto(slotIdx);
                                        }
                                      }}
                                    >
                                      {myPhotos.length > 1 ? "Remove" : "Swap"}
                                    </button>
                                  )}
                                </div>
                              );
                            })}
                          </div>
                        </div>

                        {/* Personal Info Fields */}
                        <div className={styles.glassSurfaceCard}>
                          <h2 className={styles.viewHeader}>
                            Personal Details
                          </h2>

                          <label className={styles.fieldGroup}>
                            <span className={styles.fieldLabel}>
                              Display Name
                            </span>
                            <input
                              type="text"
                              className={styles.glassInput}
                              value={userName}
                              onChange={(e) => setUserName(e.target.value)}
                            />
                          </label>

                          <label className={styles.fieldGroup}>
                            <span className={styles.fieldLabel}>Age</span>
                            <input
                              type="number"
                              min={18}
                              max={80}
                              className={styles.glassInput}
                              value={userAge}
                              onChange={(e) =>
                                setUserAge(
                                  Math.max(
                                    18,
                                    Math.min(80, Number(e.target.value) || 18)
                                  )
                                )
                              }
                            />
                          </label>

                          <label className={styles.fieldGroup}>
                            <span className={styles.fieldLabel}>
                              Phone Number
                            </span>
                            <input
                              type="tel"
                              className={styles.glassInput}
                              value={userPhone}
                              onChange={(e) => setUserPhone(e.target.value)}
                            />
                          </label>

                          <label className={styles.fieldGroup}>
                            <span className={styles.fieldLabel}>
                              Occupation
                            </span>
                            <input
                              type="text"
                              className={styles.glassInput}
                              value={userOccupation}
                              onChange={(e) =>
                                setUserOccupation(e.target.value)
                              }
                            />
                          </label>

                          <label className={styles.fieldGroup}>
                            <span className={styles.fieldLabel}>Education</span>
                            <input
                              type="text"
                              className={styles.glassInput}
                              value={userEducation}
                              onChange={(e) => setUserEducation(e.target.value)}
                            />
                          </label>

                          <label className={styles.fieldGroup}>
                            <span className={styles.fieldLabel}>
                              City & State
                            </span>
                            <input
                              type="text"
                              className={styles.glassInput}
                              value={userNeighborhood}
                              onChange={(e) =>
                                setUserNeighborhood(e.target.value)
                              }
                            />
                          </label>

                          <label className={styles.fieldGroup}>
                            <span className={styles.fieldLabel}>Bio</span>
                            <input
                              type="text"
                              className={styles.glassInput}
                              value={userBio}
                              onChange={(e) => setUserBio(e.target.value)}
                            />
                          </label>

                          <label className={styles.fieldGroup}>
                            <span className={styles.fieldLabel}>
                              Profile Prompt
                            </span>
                            <input
                              type="text"
                              className={styles.glassInput}
                              value={userPromptAnswer}
                              onChange={(e) =>
                                setUserPromptAnswer(e.target.value)
                              }
                            />
                          </label>

                          <div
                            style={{
                              display: "flex",
                              alignItems: "center",
                              justifyContent: "space-between",
                              padding: "10px 0",
                            }}
                          >
                            <div>
                              <div
                                style={{ fontSize: "14px", fontWeight: 700 }}
                              >
                                Selfie Verification Badge
                              </div>
                              <div
                                style={{
                                  fontSize: "12px",
                                  color: "var(--lg-muted)",
                                }}
                              >
                                {isViewerVerified
                                  ? "Verified badge shown next to your name"
                                  : "Tap to verify your profile"}
                              </div>
                            </div>
                            <button
                              type="button"
                              className={`${styles.iosSwitchBtn} ${
                                isViewerVerified
                                  ? styles.iosSwitchBtnActive
                                  : ""
                              }`}
                              onClick={() =>
                                setIsViewerVerified((prev) => !prev)
                              }
                              aria-label="Toggle verification"
                            >
                              <div
                                className={`${styles.iosSwitchThumb} ${
                                  isViewerVerified
                                    ? styles.iosSwitchThumbActive
                                    : ""
                                }`}
                              />
                            </button>
                          </div>

                          <button
                            type="button"
                            className={styles.primaryCapsuleBtn}
                            onClick={() => {
                              setProfileSubPage(null);
                              showToast("Profile updated ✓");
                            }}
                          >
                            Save Profile Changes
                          </button>
                        </div>
                      </section>
                    ) : profileSubPage === "your_likes" ? (
                      /* SUB-VIEW 2: Your Likes */
                      <section className={styles.fullPageScreen}>
                        <header className={styles.fullPageTopBar}>
                          <div>
                            <div className={styles.paidBadgeText}>Settings</div>
                            <h1 className={styles.viewHeader}>
                              Your Likes ({likedProfilesList.length})
                            </h1>
                          </div>
                          <button
                            type="button"
                            className={styles.topFilterOrb}
                            onClick={() => setProfileSubPage(null)}
                          >
                            <SoftCloseIcon size={18} />
                          </button>
                        </header>

                        {likedProfilesList.length === 0 ? (
                          <div className={styles.glassSurfaceCard}>
                            <p className={styles.viewSubtext}>
                              You haven&apos;t liked any profiles yet. Explore Discovery to send likes and comments!
                            </p>
                          </div>
                        ) : (
                          <div className={styles.matchList}>
                            {likedProfilesList.map((person) => (
                              <div
                                key={person.id}
                                className={styles.glassSurfaceCard}
                                style={{ padding: "14px" }}
                              >
                                <div className={styles.paidIntroHeader}>
                                  <div
                                    className={styles.avatarThumb}
                                    style={{
                                      backgroundImage: `url(${person.photos[0]})`,
                                    }}
                                  />
                                  <div style={{ flex: 1 }}>
                                    <div className={styles.matchPartnerName}>
                                      <span>
                                        {person.name}, {person.age}
                                      </span>
                                      {person.isVerified && (
                                        <span
                                          style={{
                                            color: "#F93666",
                                            display: "flex",
                                          }}
                                        >
                                          <SoftVerifiedBadgeIcon size={14} />
                                        </span>
                                      )}
                                    </div>
                                    <div className={styles.viewSubtext}>
                                      {person.occupation} · {person.community} ·{" "}
                                      {person.neighborhood}
                                    </div>
                                  </div>
                                </div>
                                <div style={{ display: "flex", gap: "8px" }}>
                                  <button
                                    type="button"
                                    className={styles.primaryCapsuleBtn}
                                    style={{
                                      flex: 1,
                                      minHeight: "40px",
                                      fontSize: "13px",
                                    }}
                                    onClick={() => {
                                      setFullScreenProfile(person);
                                    }}
                                  >
                                    View Profile
                                  </button>
                                  <button
                                    type="button"
                                    className={styles.filterChip}
                                    onClick={() =>
                                      setQuickMsgCandidate(person)
                                    }
                                  >
                                    Send Comment
                                  </button>
                                </div>
                              </div>
                            ))}
                          </div>
                        )}
                      </section>
                    ) : profileSubPage === "recent_passes" ? (
                      /* SUB-VIEW 3: Recent Passes */
                      <section className={styles.fullPageScreen}>
                        <header className={styles.fullPageTopBar}>
                          <div>
                            <div className={styles.paidBadgeText}>
                              Second Look
                            </div>
                            <h1 className={styles.viewHeader}>
                              Recent Passes ({passedProfilesList.length})
                            </h1>
                          </div>
                          <button
                            type="button"
                            className={styles.topFilterOrb}
                            onClick={() => setProfileSubPage(null)}
                          >
                            <SoftCloseIcon size={18} />
                          </button>
                        </header>

                        {passedProfilesList.length === 0 ? (
                          <div className={styles.glassSurfaceCard}>
                            <p className={styles.viewSubtext}>
                              No recent passes! Anyone you skip in Discovery will appear here so you can give them a second chance.
                            </p>
                          </div>
                        ) : (
                          <div className={styles.matchList}>
                            {passedProfilesList.map((person) => (
                              <div
                                key={person.id}
                                className={styles.glassSurfaceCard}
                                style={{ padding: "14px" }}
                              >
                                <div className={styles.paidIntroHeader}>
                                  <div
                                    className={styles.avatarThumb}
                                    style={{
                                      backgroundImage: `url(${person.photos[0]})`,
                                    }}
                                  />
                                  <div style={{ flex: 1 }}>
                                    <div className={styles.matchPartnerName}>
                                      <span>
                                        {person.name}, {person.age}
                                      </span>
                                    </div>
                                    <div className={styles.viewSubtext}>
                                      {person.occupation} ·{" "}
                                      {person.neighborhood}
                                    </div>
                                  </div>
                                  <button
                                    type="button"
                                    className={styles.primaryCapsuleBtn}
                                    style={{
                                      minHeight: "38px",
                                      padding: "0 14px",
                                      fontSize: "13px",
                                    }}
                                    onClick={() => {
                                      setPassedIds((prev) =>
                                        prev.filter((id) => id !== person.id)
                                      );
                                      setSwipedIds((prev) =>
                                        prev.filter((id) => id !== person.id)
                                      );
                                      setLikedIds((prev) =>
                                        prev.includes(person.id)
                                          ? prev
                                          : [person.id, ...prev]
                                      );
                                      showToast(
                                        `Reconnected with ${person.name} ✓`
                                      );
                                    }}
                                  >
                                    Reconnect
                                  </button>
                                </div>
                              </div>
                            ))}
                          </div>
                        )}
                      </section>
                    ) : profileSubPage === "safety_tips" ? (
                      /* SUB-VIEW 4: Safety Tips */
                      <section className={styles.fullPageScreen}>
                        <header className={styles.fullPageTopBar}>
                          <div>
                            <div className={styles.paidBadgeText}>
                              Trust & Protection
                            </div>
                            <h1 className={styles.viewHeader}>Safety Tips</h1>
                          </div>
                          <button
                            type="button"
                            className={styles.topFilterOrb}
                            onClick={() => setProfileSubPage(null)}
                          >
                            <SoftCloseIcon size={18} />
                          </button>
                        </header>

                        <div className={styles.glassSurfaceCard}>
                          <h2 className={styles.viewHeader}>
                            1. Look for the Verified Checkmark
                          </h2>
                          <p className={styles.viewSubtext}>
                            Profiles with a verified badge have passed live selfie authentication. Always prioritize verified members when planning an in-person date.
                          </p>
                        </div>

                        <div className={styles.glassSurfaceCard}>
                          <h2 className={styles.viewHeader}>
                            2. Keep Early Conversations on jdate
                          </h2>
                          <p className={styles.viewSubtext}>
                            Get to know your match using our built-in messaging before sharing personal phone numbers, workplace details, or home addresses.
                          </p>
                        </div>

                        <div className={styles.glassSurfaceCard}>
                          <h2 className={styles.viewHeader}>
                            3. Meet in Public & Share Your Plans
                          </h2>
                          <p className={styles.viewSubtext}>
                            For your first few dates, meet at a busy coffee shop or restaurant and let a trusted friend or family member know your schedule.
                          </p>
                        </div>
                      </section>
                    ) : profileSubPage === "help_center" ? (
                      /* SUB-VIEW 5: Help Center */
                      <section className={styles.fullPageScreen}>
                        <header className={styles.fullPageTopBar}>
                          <div>
                            <div className={styles.paidBadgeText}>
                              24/7 Member Support
                            </div>
                            <h1 className={styles.viewHeader}>Help Center</h1>
                          </div>
                          <button
                            type="button"
                            className={styles.topFilterOrb}
                            onClick={() => setProfileSubPage(null)}
                          >
                            <SoftCloseIcon size={18} />
                          </button>
                        </header>

                        <div className={styles.glassSurfaceCard}>
                          <h2 className={styles.viewHeader}>
                            Frequently Asked Questions
                          </h2>
                          <div className={styles.vitalCard}>
                            <div className={styles.vitalValue}>
                              How does Save Search work?
                            </div>
                            <p
                              className={styles.viewSubtext}
                              style={{ marginTop: "4px" }}
                            >
                              Your age, height, faith, community, and mother tongue preferences are saved immediately to curate your Discovery deck.
                            </p>
                          </div>
                          <div className={styles.vitalCard}>
                            <div className={styles.vitalValue}>
                              How do I increase my Profile % badge?
                            </div>
                            <p
                              className={styles.viewSubtext}
                              style={{ marginTop: "4px" }}
                            >
                              Tap the pencil icon on your profile photo to add up to 6 photos, complete your bio, and enable selfie verification.
                            </p>
                          </div>
                        </div>

                        <form
                          className={styles.glassSurfaceCard}
                          onSubmit={(e) => {
                            e.preventDefault();
                            if (!supportTicketText.trim()) return;
                            setSupportTicketText("");
                            showToast(
                              "Support message received — we'll reply shortly"
                            );
                          }}
                        >
                          <h2 className={styles.viewHeader}>
                            Contact Concierge Support
                          </h2>
                          <input
                            type="text"
                            className={styles.glassInput}
                            placeholder="Describe your question or feedback..."
                            value={supportTicketText}
                            onChange={(e) =>
                              setSupportTicketText(e.target.value)
                            }
                            required
                          />
                          <button
                            type="submit"
                            className={styles.primaryCapsuleBtn}
                          >
                            Send Message to Support
                          </button>
                        </form>
                      </section>
                    ) : (
                      /* MINIMAL PROFILE HUB:
                         1. Clean Identity Header with Single Edit Button (no photo badge, no 29% bar)
                         2. Clean White Card with Rose Accent, 3 Short Perks, and Upgrade CTA
                         3. 4 Essential Rows (Your Likes, Recent Passes, Safety Tips, Help Center) */
                      <section className={styles.profileTabContainer}>
                        {/* 1. Minimal Identity Header Card */}
                        <div className={styles.editorialProfileCard}>
                          <div className={styles.editorialIdentityTop}>
                            <div className={styles.editorialAvatarFrame}>
                              <div
                                className={styles.editorialAvatarImg}
                                style={{
                                  backgroundImage: `url(${myPhotos[0]})`,
                                }}
                              />
                            </div>

                            <div className={styles.editorialMetaCol}>
                              <div className={styles.editorialNameRow}>
                                <span className={styles.editorialNameText}>
                                  {userName}, {userAge}
                                </span>
                                {isViewerVerified && (
                                  <span className={styles.editorialVerifiedBadge}>
                                    <SoftVerifiedBadgeIcon size={13} />
                                    <span>Verified</span>
                                  </span>
                                )}
                              </div>
                              <div className={styles.editorialRoleSubline}>
                                {userOccupation} · {userNeighborhood}
                              </div>
                            </div>

                            <button
                              type="button"
                              className={styles.editorialEditBtn}
                              onClick={() => setProfileSubPage("edit_profile")}
                            >
                              <EditPencilIcon size={14} />
                              <span>Edit</span>
                            </button>
                          </div>
                        </div>

                        {/* 2. Clean White Card with Rose Accent, 3 Short Perks & Upgrade CTA */}
                        <div className={styles.subShowcaseCard}>
                          {/* Top Segmented Tier Tabs */}
                          <div className={styles.subTierTabsBar}>
                            {SUBSCRIPTION_TIERS.map((tier, idx) => {
                              const isTabActive = idx === conciergeSlideIdx;
                              return (
                                <button
                                  key={tier.id}
                                  type="button"
                                  className={`${styles.subTierTabBtn} ${
                                    isTabActive
                                      ? styles.subTierTabBtnActive
                                      : ""
                                  }`}
                                  onClick={() => setConciergeSlideIdx(idx)}
                                >
                                  <span>{tier.title}</span>
                                </button>
                              );
                            })}
                          </div>

                          {/* Tier Header Row */}
                          <div className={styles.subShowcaseHeaderRow}>
                            <div className={styles.subShowcaseTitleGroup}>
                              <span className={styles.subShowcaseIconBadge}>
                                {activeSubscriptionTier.id === "premium" ? (
                                  <SoftHeartIcon size={18} />
                                ) : activeSubscriptionTier.id ===
                                  "premium_plus" ? (
                                  <SoftStarIcon size={18} />
                                ) : (
                                  <LuxeCrownIcon size={18} />
                                )}
                              </span>
                              <div>
                                <div className={styles.subShowcaseEyebrow}>
                                  {activeSubscriptionTier.badge}
                                </div>
                                <h3 className={styles.subShowcaseTitle}>
                                  Naam {activeSubscriptionTier.title}
                                </h3>
                              </div>
                            </div>

                            <div className={styles.subShowcasePricePill}>
                              {activeSubscriptionTier.price}
                            </div>
                          </div>

                          {/* 3 Concise Perks */}
                          <div className={styles.subFeaturesList}>
                            {activeSubscriptionTier.features.map(
                              (featureText, fIdx) => (
                                <div
                                  key={fIdx}
                                  className={styles.subFeatureItem}
                                >
                                  <span className={styles.subFeatureCheckOrb}>
                                    ✓
                                  </span>
                                  <span className={styles.subFeatureText}>
                                    {featureText}
                                  </span>
                                </div>
                              )
                            )}
                          </div>

                          {/* Action CTA Button */}
                          <button
                            type="button"
                            className={styles.subShowcaseCtaBtn}
                            onClick={() => setActivePlanModal("concierge")}
                          >
                            <span>
                              {isConciergeActive
                                ? `Active: Naam ${activeSubscriptionTier.title}`
                                : `Upgrade to ${activeSubscriptionTier.title}`}
                            </span>
                            <ChevronRightIcon size={17} />
                          </button>
                        </div>

                        {/* 3. Clean Minimal Settings Rows (Your Likes, Recent Passes, Safety Tips, Help Center) */}
                        <div className={styles.minimalSettingsCard}>
                          <button
                            type="button"
                            className={styles.minimalSettingRow}
                            onClick={() => setProfileSubPage("your_likes")}
                          >
                            <div className={styles.minimalSettingLeft}>
                              <span className={styles.minimalSettingIcon}>
                                <HeartOutlineIcon size={20} />
                              </span>
                              <span className={styles.minimalSettingTitle}>
                                Your Likes
                              </span>
                            </div>
                            <span className={styles.minimalSettingArrow}>
                              <ChevronRightIcon size={18} />
                            </span>
                          </button>

                          <button
                            type="button"
                            className={styles.minimalSettingRow}
                            onClick={() => setProfileSubPage("recent_passes")}
                          >
                            <div className={styles.minimalSettingLeft}>
                              <span className={styles.minimalSettingIcon}>
                                <RecentPassesBoxIcon size={20} />
                              </span>
                              <span className={styles.minimalSettingTitle}>
                                Recent Passes
                              </span>
                            </div>
                            <span className={styles.minimalSettingArrow}>
                              <ChevronRightIcon size={18} />
                            </span>
                          </button>

                          <button
                            type="button"
                            className={styles.minimalSettingRow}
                            onClick={() => setProfileSubPage("safety_tips")}
                          >
                            <div className={styles.minimalSettingLeft}>
                              <span className={styles.minimalSettingIcon}>
                                <SafetyShieldIcon size={20} />
                              </span>
                              <span className={styles.minimalSettingTitle}>
                                Safety Tips
                              </span>
                            </div>
                            <span className={styles.minimalSettingArrow}>
                              <ChevronRightIcon size={18} />
                            </span>
                          </button>

                          <button
                            type="button"
                            className={styles.minimalSettingRow}
                            onClick={() => setProfileSubPage("help_center")}
                          >
                            <div className={styles.minimalSettingLeft}>
                              <span className={styles.minimalSettingIcon}>
                                <HelpCircleIcon size={20} />
                              </span>
                              <span className={styles.minimalSettingTitle}>
                                Help Center
                              </span>
                            </div>
                            <span className={styles.minimalSettingArrow}>
                              <ChevronRightIcon size={18} />
                            </span>
                          </button>
                        </div>
                      </section>
                    )}
                  </>
                )}
              </main>
            </>
          )}

          {/* Clean Full-Width Docked Bottom Navigation Bar — Hidden Inside Full-Screen Chat or Profile Detail View */}
          {!fullScreenChatThread && !fullScreenProfile && (
            <div className={styles.bottomTabBarWrapper}>
              <nav
                className={styles.bottomTabBar}
                aria-label="Primary Navigation"
              >
                <button
                  type="button"
                  className={`${styles.bottomTabItem} ${
                    activeTab === "discover" ? styles.bottomTabItemActive : ""
                  }`}
                  onClick={() => {
                    setFullScreenProfile(null);
                    setFullScreenChatThread(null);
                    setProfileSubPage(null);
                    setActiveTab("discover");
                  }}
                >
                  <span className={styles.bottomTabIconWrap}>
                    <SoftCompassIcon size={22} />
                  </span>
                  <span>Discover</span>
                </button>

                <button
                  type="button"
                  className={`${styles.bottomTabItem} ${
                    activeTab === "matches" ? styles.bottomTabItemActive : ""
                  }`}
                  onClick={() => {
                    setFullScreenProfile(null);
                    setFullScreenChatThread(null);
                    setProfileSubPage(null);
                    setActiveTab("matches");
                  }}
                >
                  <span className={styles.bottomTabIconWrap}>
                    <HeartOutlineIcon size={22} />
                  </span>
                  <span>Likes</span>
                </button>

                <button
                  type="button"
                  className={`${styles.bottomTabItem} ${
                    activeTab === "messages" ? styles.bottomTabItemActive : ""
                  }`}
                  onClick={() => {
                    setFullScreenProfile(null);
                    setFullScreenChatThread(null);
                    setProfileSubPage(null);
                    setActiveTab("messages");
                  }}
                >
                  <span className={styles.bottomTabIconWrap}>
                    <SoftChatIcon size={21} />
                    {unreadThreadCount > 0 && (
                      <span className={styles.tabUnreadBadge}>
                        {unreadThreadCount}
                      </span>
                    )}
                  </span>
                  <span>Chats</span>
                </button>

                <button
                  type="button"
                  className={`${styles.bottomTabItem} ${
                    activeTab === "profile" ? styles.bottomTabItemActive : ""
                  }`}
                  onClick={() => {
                    setFullScreenProfile(null);
                    setFullScreenChatThread(null);
                    setProfileSubPage(null);
                    setActiveTab("profile");
                  }}
                >
                  <span className={styles.bottomTabIconWrap}>
                    <SoftUserIcon size={21} />
                  </span>
                  <span>You</span>
                </button>
              </nav>
            </div>
          )}
        </div>

        {/* Floating Quick-Message / Comment Sheet */}
        {quickMsgCandidate && (
          <div
            className={styles.sheetOverlay}
            onClick={() => setQuickMsgCandidate(null)}
          >
            <form
              onSubmit={handleSendQuickMessage}
              className={styles.glassBottomSheet}
              onClick={(e) => e.stopPropagation()}
            >
              <div className={styles.sheetGrabHandle} />
              <div className={styles.sheetHeaderRow}>
                <div>
                  <h2 className={styles.viewHeader}>
                    Send Comment to {quickMsgCandidate.name}
                  </h2>
                  <p className={styles.viewSubtext}>
                    You have {commentCredits} Comment credits remaining.
                  </p>
                </div>
                <button
                  type="button"
                  className={styles.topFilterOrb}
                  onClick={() => setQuickMsgCandidate(null)}
                >
                  <SoftCloseIcon size={18} />
                </button>
              </div>

              <input
                type="text"
                className={styles.glassInput}
                placeholder={`Write an intentional comment to ${quickMsgCandidate.name}...`}
                value={quickMsgText}
                onChange={(e) => setQuickMsgText(e.target.value)}
                autoFocus
                required
              />

              <button type="submit" className={styles.primaryCapsuleBtn}>
                <SoftChatIcon size={18} />
                <span>Send Comment</span>
              </button>
            </form>
          </div>
        )}

        {/* Subscription Tier Confirmation Modal */}
        {activePlanModal && (
          <div
            className={styles.sheetOverlay}
            onClick={() => setActivePlanModal(null)}
          >
            <div
              className={styles.glassBottomSheet}
              onClick={(e) => e.stopPropagation()}
            >
              <div className={styles.sheetGrabHandle} />
              <div className={styles.sheetHeaderRow}>
                <div>
                  <div
                    className={styles.paidBadgeText}
                    style={{ color: "#F93666" }}
                  >
                    {activeSubscriptionTier.badge}
                  </div>
                  <h2 className={styles.viewHeader}>
                    Naam {activeSubscriptionTier.title} ·{" "}
                    {activeSubscriptionTier.price}
                  </h2>
                </div>
                <button
                  type="button"
                  className={styles.topFilterOrb}
                  onClick={() => setActivePlanModal(null)}
                >
                  <SoftCloseIcon size={18} />
                </button>
              </div>

              <p className={styles.viewSubtext}>
                {activeSubscriptionTier.perk}
              </p>

              <div className={styles.modalFeaturesCheckList}>
                {activeSubscriptionTier.features.map((feat, i) => (
                  <div key={i} className={styles.modalFeatureCheckRow}>
                    <span className={styles.modalFeatureCheckMark}>✓</span>
                    <span>{feat}</span>
                  </div>
                ))}
              </div>

              <button
                type="button"
                className={styles.primaryCapsuleBtn}
                onClick={() => {
                  setIsConciergeActive(true);
                  showToast(`${activeSubscriptionTier.title} activated ✓`);
                  setActivePlanModal(null);
                }}
              >
                Activate {activeSubscriptionTier.title}
              </button>
            </div>
          </div>
        )}

        {/* REDESIGNED FILTER / PREFERENCES SCREEN (Matches Reference Image 1 + #F93666 Save Search Button) */}
        {isFilterSheetOpen && (
          <div
            className={styles.preferencesOverlay}
            onClick={() => setIsFilterSheetOpen(false)}
          >
            <div
              className={styles.preferencesScreen}
              onClick={(e) => e.stopPropagation()}
            >
              <div className={styles.preferencesScrollBody}>
                {/* Top Bar: Black Reset Button on Left, Downward Chevron on Right */}
                <div className={styles.preferencesTopBar}>
                  <button
                    type="button"
                    className={styles.preferencesResetBtn}
                    onClick={() => {
                      handleResetFilters();
                      showToast("Search filters reset");
                    }}
                  >
                    Reset
                  </button>
                  <button
                    type="button"
                    className={styles.preferencesCloseBtn}
                    onClick={() => setIsFilterSheetOpen(false)}
                    aria-label="Collapse Filter"
                  >
                    <ChevronDownIcon size={28} />
                  </button>
                </div>

                {/* 1. Inline Age Range Slider (18-29) */}
                <div className={styles.inlineSliderSection}>
                  <div className={styles.inlineSliderHeader}>
                    <span className={styles.inlineSliderTitle}>Age</span>
                    <span className={styles.inlineSliderValue}>
                      {minAge}-{maxAge}
                    </span>
                  </div>
                  <div className={styles.dualRangeWrapper}>
                    <div className={styles.dualRangeTrack} />
                    <div
                      className={styles.dualRangeFill}
                      style={{
                        left: `${((minAge - 18) / 42) * 100}%`,
                        width: `${((maxAge - minAge) / 42) * 100}%`,
                      }}
                    />
                    <input
                      type="range"
                      min={18}
                      max={60}
                      value={minAge}
                      aria-label="Minimum Age"
                      className={styles.dualRangeInput}
                      onChange={(e) => {
                        const val = Math.min(
                          Number(e.target.value),
                          maxAge - 1
                        );
                        setMinAge(val);
                      }}
                    />
                    <input
                      type="range"
                      min={18}
                      max={60}
                      value={maxAge}
                      aria-label="Maximum Age"
                      className={styles.dualRangeInput}
                      onChange={(e) => {
                        const val = Math.max(
                          Number(e.target.value),
                          minAge + 1
                        );
                        setMaxAge(val);
                      }}
                    />
                  </div>
                </div>

                {/* 2. Inline Height Range Slider (4'0"-8'0") */}
                <div className={styles.inlineSliderSection}>
                  <div className={styles.inlineSliderHeader}>
                    <span className={styles.inlineSliderTitle}>Height</span>
                    <span className={styles.inlineSliderValue}>
                      {formatInchesToFeetLabel(minHeightInches)}-
                      {formatInchesToFeetLabel(maxHeightInches)}
                    </span>
                  </div>
                  <div className={styles.dualRangeWrapper}>
                    <div className={styles.dualRangeTrack} />
                    <div
                      className={styles.dualRangeFill}
                      style={{
                        left: `${((minHeightInches - 48) / 48) * 100}%`,
                        width: `${
                          ((maxHeightInches - minHeightInches) / 48) * 100
                        }%`,
                      }}
                    />
                    <input
                      type="range"
                      min={48}
                      max={96}
                      value={minHeightInches}
                      aria-label="Minimum Height"
                      className={styles.dualRangeInput}
                      onChange={(e) => {
                        const val = Math.min(
                          Number(e.target.value),
                          maxHeightInches - 1
                        );
                        setMinHeightInches(val);
                      }}
                    />
                    <input
                      type="range"
                      min={48}
                      max={96}
                      value={maxHeightInches}
                      aria-label="Maximum Height"
                      className={styles.dualRangeInput}
                      onChange={(e) => {
                        const val = Math.max(
                          Number(e.target.value),
                          minHeightInches + 1
                        );
                        setMaxHeightInches(val);
                      }}
                    />
                  </div>
                </div>

                {/* 3. Sort By Activity Row with iOS Switch */}
                <div className={styles.sortActivityRow}>
                  <span className={styles.inlineSliderTitle}>
                    Sort By Activity
                  </span>
                  <button
                    type="button"
                    role="switch"
                    aria-checked={sortByActivity}
                    className={`${styles.iosSwitchBtn} ${
                      sortByActivity ? styles.iosSwitchBtnActive : ""
                    }`}
                    onClick={() => setSortByActivity((v) => !v)}
                  >
                    <div
                      className={`${styles.iosSwitchThumb} ${
                        sortByActivity ? styles.iosSwitchThumbActive : ""
                      }`}
                    />
                  </button>
                </div>

                {/* 4. Expandable Accordion Rows: Status, Faith, Community, Mother Tongue, Country, State, Smoking, Interested In */}
                <div className={styles.preferencesList}>
                  {FILTER_ACCORDION_SECTIONS.map((sec) => {
                    const isOpen = expandedPrefKey === sec.key;
                    const currentVal = filterSelections[sec.key] ?? "Any";
                    const isDefault =
                      currentVal === "Any" || currentVal === "Everyone";

                    return (
                      <div key={sec.key} className={styles.preferenceItemBlock}>
                        <button
                          type="button"
                          className={styles.preferenceRowBtn}
                          onClick={() =>
                            setExpandedPrefKey((prev) =>
                              prev === sec.key ? null : sec.key
                            )
                          }
                        >
                          <span
                            className={`${styles.preferenceAccordionTitle} ${
                              !isDefault || isOpen
                                ? styles.preferenceAccordionTitleActive
                                : ""
                            }`}
                          >
                            {sec.label}
                          </span>
                          <div className={styles.preferenceAccordionRight}>
                            {!isDefault && (
                              <span className={styles.preferenceSelectedTag}>
                                {currentVal}
                              </span>
                            )}
                            <span
                              className={`${styles.preferenceChevronIcon} ${
                                isOpen ? styles.preferenceChevronOpen : ""
                              }`}
                            >
                              <ChevronDownIcon size={20} />
                            </span>
                          </div>
                        </button>

                        {isOpen && (
                          <div className={styles.preferenceExpandPanel}>
                            <div className={styles.SelectableWrap}>
                              {sec.options.map((opt) => (
                                <button
                                  key={opt}
                                  type="button"
                                  className={`${styles.filterChip} ${
                                    currentVal === opt
                                      ? styles.filterChipActive
                                      : ""
                                  }`}
                                  onClick={() =>
                                    setFilterSelections((prev) => ({
                                      ...prev,
                                      [sec.key]: opt,
                                    }))
                                  }
                                >
                                  {opt}
                                </button>
                              ))}
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Sticky Bottom Save Search Button (#F93666) */}
              <div className={styles.saveSearchStickyFooter}>
                <button
                  type="button"
                  className={styles.saveSearchBtn}
                  onClick={() => {
                    setIsFilterSheetOpen(false);
                    showToast("Search preferences saved ✓");
                  }}
                >
                  Save Search
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
};

export default Home;
