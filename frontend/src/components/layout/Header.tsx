import Link from "next/link";
import styles from "@/styles/Layout.module.css";
import { APP_NAME } from "@/utils/constants";

export default function Header() {
  return (
    <header className={styles.header}>
      <Link href="/" className={styles.logo} style={{ display: "inline-flex", alignItems: "center" }}>
        <img
          src="/assets/aistudio/image_cd9da323.png"
          alt={APP_NAME}
          style={{ height: "18px", width: "auto", objectFit: "contain" }}
        />
      </Link>
      <nav className={styles.nav}>
        <Link href="/dashboard">Dashboard</Link>
        <Link href="/profile">Profile</Link>
        <Link href="/login">Login</Link>
        <Link href="/register">Register</Link>
      </nav>
    </header>
  );
}
