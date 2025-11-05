import * as React from "react";
import * as TabsPrimitive from "@radix-ui/react-tabs";

import { cn } from "@/lib/utils";

function Tabs({
  className,
  ...props
}: React.ComponentProps<typeof TabsPrimitive.Root>) {
  return (
    <TabsPrimitive.Root
      data-slot="tabs"
      className={cn("flex flex-col", className)}
      {...props}
    />
  );
}

function TabsList({
  className,
  ...props
}: React.ComponentProps<typeof TabsPrimitive.List>) {
  return (
    <TabsPrimitive.List
      data-slot="tabs-list"
      className={cn(
        "inline-flex items-center justify-center",
        "flex border-b-0",
        className,
      )}
      {...props}
    />
  );
}

function TabsTrigger({
  className,
  ...props
}: React.ComponentProps<typeof TabsPrimitive.Trigger>) {
  return (
    <TabsPrimitive.Trigger
      data-slot="tabs-trigger"
      className={cn(
        "inline-flex w-150 items-center justify-center pb-4 whitespace-nowrap",
        "font-aeonik text-md font-medium",
        "transition-all disabled:pointer-events-none disabled:opacity-50",
        "text-primary-foreground border-b-2",
        "data-[state=inactive]:hover:text-tertiary-strong-hover data-[state=inactive]:hover:border-tertiary-strong-hover",
        "data-[state=inactive]:text-tertiary-strong data-[state=inactive]:border-tertiary-strong",
        "data-[state=active]:text-primary-foreground data-[state=active]:border-primary-foreground",
        "focus-visible:ring-ring focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none",
        className,
      )}
      {...props}
    />
  );
}

const TabsContent = React.forwardRef<
  HTMLDivElement,
  React.ComponentProps<typeof TabsPrimitive.Content>
>(({ className, ...props }, ref) => {
  return (
    <TabsPrimitive.Content
      ref={ref}
      data-slot="tabs-content"
      className={cn("mt-10 outline-none", className)}
      {...props}
    />
  );
});

export { Tabs, TabsList, TabsTrigger, TabsContent };
