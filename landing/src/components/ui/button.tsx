import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-full font-aeonik cursor-pointer text-md transition-all disabled:opacity-50 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
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
        default: "max-sm:w-full px-6 py-3 md:py-3",
        sm: "max-sm:w-full px-5 py-3 md:py-3.5",
        xs: "max-sm:w-[calc(100%-50px)] px-3 py-3 md:py-3",
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
      <div className="flex items-center justify-center">{children}</div>
    </Comp>
  );
}

export { Button, buttonVariants };
