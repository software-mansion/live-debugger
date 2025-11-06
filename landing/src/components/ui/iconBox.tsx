import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils";

const iconBoxVariants = cva(
  "flex items-center flex-col justify-center rounded-lg p-1 h-12 w-12 md:h-14 md:w-14 lg:h-16 lg:w-16",
  {
    variants: {
      variant: {
        primary: "bg-primary text-primary-foreground",
        secondary: "bg-slate-300 text-secondary-strong-foreground",
      },
    },
    defaultVariants: {
      variant: "primary",
    },
  },
);

function IconBox({
  className,
  variant,
  asChild = false,
  children,
  ...props
}: React.HTMLAttributes<HTMLDivElement> &
  VariantProps<typeof iconBoxVariants> & {
    asChild?: boolean;
  }) {
  return (
    <div
      data-slot="button"
      className={cn(iconBoxVariants({ variant, className }))}
      {...props}
    >
      {children}
    </div>
  );
}

export { IconBox, iconBoxVariants };
