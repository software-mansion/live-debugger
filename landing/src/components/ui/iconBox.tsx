import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils";

const iconBoxVariants = cva(
  "inline-flex items-center flex-col justify-center w-16 h-16 p-8 rounded-lg",
  {
    variants: {
      variant: {
        primary: "bg-primary text-primary-foreground",
        secondary: "bg-slate-300 text-secondary-strong-foreground",
      },
      size: {
        default: "p-1 [&_svg:not([class*='size-'])]:size-10",
        sm: "p-1 [&_svg:not([class*='size-'])]:size-8",
      },
    },
    defaultVariants: {
      variant: "primary",
      size: "default",
    },
  },
);

function IconBox({
  className,
  variant,
  size,
  asChild = false,
  children,
  ...props
}: React.HTMLAttributes<HTMLDivElement> &
  VariantProps<typeof iconBoxVariants> & {
    asChild?: boolean;
  }) {
  return (
    <span
      data-slot="button"
      className={cn(iconBoxVariants({ variant, size, className }))}
      {...props}
    >
      <div className="flex items-center justify-center gap-2.5 px-2">
        {children}
      </div>
    </span>
  );
}

export { IconBox, iconBoxVariants };
