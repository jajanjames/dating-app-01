import type { NextPage } from "next";
import Head from "next/head";
import Link from "next/link";
import { useRouter } from "next/router";
import { useState, type FormEvent } from "react";
import Layout from "@/components/layout/Layout";
import Input from "@/components/common/Input";
import Button from "@/components/common/Button";
import styles from "@/styles/Auth.module.css";
import { authService } from "@/services/auth.service";
import { APP_NAME, AUTH_TOKEN_KEY } from "@/utils/constants";

const RegisterPage: NextPage = () => {
  const router = useRouter();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    setIsLoading(true);
    try {
      const response = await authService.register(name, email, password);
      if (typeof window !== "undefined") {
        localStorage.setItem(AUTH_TOKEN_KEY, response.accessToken);
        document.cookie = `${AUTH_TOKEN_KEY}=${response.accessToken}; Path=/; SameSite=Lax; Max-Age=86400`;
      }
      await router.push("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      <Head>
        <title>Register | {APP_NAME}</title>
      </Head>
      <Layout>
        <div className={styles.container}>
          <div className={styles.card}>
            <h1 className={styles.title}>Create an account</h1>
            {error && <p className={styles.footerText}>{error}</p>}
            <form onSubmit={handleSubmit}>
              <Input
                id="name"
                label="Name"
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
              />
              <Input
                id="email"
                label="Email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
              <Input
                id="password"
                label="Password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <Button type="submit" isLoading={isLoading}>
                Register
              </Button>
            </form>
            <p className={styles.footerText}>
              Already have an account? <Link href="/login">Login</Link>
            </p>
          </div>
        </div>
      </Layout>
    </>
  );
};

export default RegisterPage;
