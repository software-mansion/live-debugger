"use client";

import * as React from "react";
import { cn } from "@/lib/utils";
import { Copy } from "lucide-react";
import { Button } from "@/components/ui/button";

interface CodeBlockProps extends React.HTMLAttributes<HTMLPreElement> {
  codeString: string;
}

export function CodeBlock({ codeString, ...props }: CodeBlockProps) {
  const [isCopied, setIsCopied] = React.useState(false);

  const handleCopy = () => {
    const textArea = document.createElement("textarea");
    textArea.value = codeString;
    document.body.appendChild(textArea);
    textArea.select();
    try {
      document.execCommand("copy");
      setIsCopied(true);
      setTimeout(() => setIsCopied(false), 2000);
    } catch (err) {
      console.error("Failed to copy text: ", err);
    }
    document.body.removeChild(textArea);
  };

  return (
    <div className="group relative">
      <Button
        variant="defaultWithOutline"
        size="xs"
        className={cn(
          "max-sm:left-1/2 max-sm:-translate-x-1/2",
          "absolute bottom-5",
          "sm:right-4 md:top-4 md:bottom-auto",
          "text-primary-foreground opacity-0 transition-opacity max-sm:opacity-100",
          "group-hover:opacity-100",
          "focus-visible:ring-ring focus-visible:opacity-100 focus-visible:ring-2",
        )}
        onClick={handleCopy}
      >
        <p className="text-medium px-3 text-sm">
          {isCopied ? "Copied!" : "Copy"}
        </p>
        {!isCopied && (
          <Copy strokeWidth={2} className="h-4 w-4 md:h-5 md:w-5" />
        )}
      </Button>
      <pre
        className={cn(
          "bg-swm-brand-80 min-h-35 overflow-x-auto p-6 max-md:pb-18 max-sm:pb-20",
          "text-primary-foreground text-sm",
          props.className,
        )}
        {...props}
      >
        <p className="font-lg font-secondary-strong font-normal">
          {codeString}
        </p>
      </pre>
    </div>
  );
}
