import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "EstateFlow CRM",
  description: "Multi-tenant real estate CRM SaaS"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}