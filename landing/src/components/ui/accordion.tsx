import * as React from "react";
import * as AccordionPrimitive from "@radix-ui/react-accordion";
import { ChevronDownIcon } from "lucide-react";

import { cn } from "@/lib/utils";

function Accordion({
  ...props
}: React.ComponentProps<typeof AccordionPrimitive.Root>) {
  return <AccordionPrimitive.Root data-slot="accordion" {...props} />;
}

function AccordionItem({
  className,
  ...props
}: React.ComponentProps<typeof AccordionPrimitive.Item>) {
  return (
    <AccordionPrimitive.Item
      data-slot="accordion-item"
      className={cn(
        "flex w-full flex-col",
        "transition-colors duration-200 not-last:mb-8",
        "data-[state=closed]:text-primary data-[state=closed]:bg-slate-200",
        "data-[state=closed]:hover:bg-slate-300",
        "data-[state=open]:bg-primary data-[state=open]:text-primary-foreground",
        className,
      )}
      {...props}
    />
  );
}

function AccordionTrigger({
  className,
  children,
  ...props
}: React.ComponentProps<typeof AccordionPrimitive.Trigger>) {
  return (
    <AccordionPrimitive.Header className="flex">
      <AccordionPrimitive.Trigger
        data-slot="accordion-trigger"
        className={cn(
          "focus-visible:border-ring focus-visible:ring-ring/50 cursor-pointer",
          "flex w-full flex-1 items-start justify-between gap-10 px-6 py-8",
          "text-left font-medium transition-all outline-none",
          "focus-visible:ring-[3px] disabled:pointer-events-none disabled:opacity-50",
          "[&[data-state=open]>svg]:rotate-180",
          className,
        )}
        {...props}
      >
        <div className="flex w-full text-base font-medium">{children}</div>
        <ChevronDownIcon className="pointer-events-none size-5 shrink-0 transition-transform duration-200" />
      </AccordionPrimitive.Trigger>
    </AccordionPrimitive.Header>
  );
}

function AccordionContent({
  className,
  children,
  ...props
}: React.ComponentProps<typeof AccordionPrimitive.Content>) {
  return (
    <AccordionPrimitive.Content
      data-slot="accordion-content"
      className="data-[state=closed]:animate-accordion-up data-[state=open]:animate-accordion-down w-full overflow-hidden"
      {...props}
    >
      {children}
    </AccordionPrimitive.Content>
  );
}

export { Accordion, AccordionItem, AccordionTrigger, AccordionContent };
