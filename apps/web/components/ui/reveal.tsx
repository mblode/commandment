import type { ReactNode } from "react";

interface RevealProps {
  children: ReactNode;
  className?: string;
}

export const Reveal = ({ children, className }: RevealProps) => (
  <div className={className}>{children}</div>
);
