import type { ComponentProps, ReactNode } from "react";

interface ProductFrameProps extends Omit<ComponentProps<"figure">, "children"> {
  children: ReactNode;
  description: string;
}

export const ProductFrame = ({
  children,
  className,
  description,
  ...props
}: ProductFrameProps) => (
  <figure className={className} {...props}>
    <div
      aria-hidden="true"
      className="overflow-hidden rounded-lg bg-night outline-1 outline-ink/25 -outline-offset-1"
    >
      {children}
    </div>
    <figcaption className="sr-only">{description}</figcaption>
  </figure>
);
