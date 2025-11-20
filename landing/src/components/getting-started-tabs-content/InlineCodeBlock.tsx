import * as React from "react";
import { cn } from "@/lib/utils";

export interface InlineCodeProps extends React.HTMLAttributes<HTMLElement> {}

const InlineCodeBlock = React.forwardRef<HTMLElement, InlineCodeProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <code
        ref={ref}
        className={cn(
          "inline-flex items-center align-baseline",
          "rounded-md border border-slate-400",
          "bg-swm-brand-80 mx-0.5 h-5 px-1.5 md:h-7",
          "text-md text-primary-foreground font-normal",
          className,
        )}
        {...props}
      >
        {children}
      </code>
    );
  },
);

InlineCodeBlock.displayName = "InlineCodeBlock";
export { InlineCodeBlock };
