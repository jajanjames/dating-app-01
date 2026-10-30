import type { ButtonHTMLAttributes } from "react";
import styles from "@/styles/Form.module.css";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  isLoading?: boolean;
}

export default function Button({ children, isLoading, disabled, ...rest }: ButtonProps) {
  return (
    <button className={styles.button} disabled={disabled || isLoading} {...rest}>
      {isLoading ? "Loading..." : children}
    </button>
  );
}
