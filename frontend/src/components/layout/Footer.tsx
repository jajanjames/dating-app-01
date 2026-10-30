import styles from "@/styles/Layout.module.css";
import { APP_NAME } from "@/utils/constants";

export default function Footer() {
  return (
    <footer className={styles.footer}>
      <p>
        &copy; {new Date().getFullYear()} {APP_NAME}. All rights reserved.
      </p>
    </footer>
  );
}
