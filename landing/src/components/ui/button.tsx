import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-full font-aeonik text-md transition-all disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary-hover",
        defaultWithOutline:
          "bg-primary text-primary-foreground border border-[1.5px] hover:bg-primary-hover",
        outline:
          "bg-primary-foreground text-primary border border-[1.5px] hover:bg-tertiary-hover",
        secondary:
          "bg-tertiary text-tertiary-foreground hover:bg-tertiary-hover",
      },
      size: {
        default: "max-sm:w-full px-5 py-3 md:py-3.5",
        sm: "max-sm:w-full px-5 py-2",
        xs: "max-sm:w-[calc(100%-50px)] px-5 py-2",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  },
);

function Button({
  className,
  variant,
  size,
  asChild = false,
  children,
  ...props
}: React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean;
  }) {
  const Comp = asChild ? Slot : "button";

  if (asChild) {
    return (
      <Comp
        data-slot="button"
        className={cn(buttonVariants({ variant, size }), className)}
        {...props}
      >
        {children}
      </Comp>
    );
  }

  return (
    <Comp
      data-slot="button"
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    >
      <div className="flex items-center justify-center gap-2.5 px-2">
        {children}
      </div>
    </Comp>
  );
}

export { Button, buttonVariants };
