import React, { useState } from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";
import { IconBox } from "@/components/ui/iconBox";
import useMediaQuery from "@/hooks/use-media-query";

import {
  Block,
  BlockContent,
  BlockSides,
  BlockSideHorizontal,
  BlockSideVertical,
} from "@/components/ui/block";

const blockWrapperVariants = cva("inline-flex ", {
  variants: {
    size: {
      default: "",
      large: "self-stretch",
    },
  },
  defaultVariants: {
    size: "default",
  },
});

const blockWrapperContentVariants = cva(
  "flex flex-col justify-start items-start overflow-hidden",
  {
    variants: {
      size: {
        default: "p-8 bg-white",
        large: "p-6 md:p-10 lg:p-14 md:w-96 lg:w-[600px] bg-bg-additional",
      },
    },
    defaultVariants: {
      size: "default",
    },
  },
);

export interface BlockWrapperProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof blockWrapperVariants> {
  header: string;
  description: string;
  isFlat?: boolean;
  asChild?: boolean;
}

function BlockWrapper({
  className,
  size,
  header,
  description,
  asChild = false,
  isFlat = false,
  children,
  ...props
}: React.ComponentProps<"div"> & BlockWrapperProps) {
  const [isHovered, setIsHovered] = useState(false);
  const isSmallScreen = useMediaQuery("(max-width: 599px)");

  const content = (
    <div
      className={cn(
        "flex flex-col items-start justify-start gap-4 lg:gap-6 md:lg:gap-5",
        size === "large" ? "self-stretch" : "self-stretch",
      )}
    >
      <div>
        <IconBox variant={isHovered ? "primary" : "secondary"}>
          {children}
        </IconBox>
      </div>
      <h3 className="text-primary text-md font-aeonik font-medium">{header}</h3>
      <div className="text-secondary font-aeonik text-sm font-normal">
        {description}
      </div>
    </div>
  );

  return (
    <Block
      transitions={true}
      onMouseEnter={(e) => {
        setIsHovered(true);
        props.onMouseEnter?.(e);
      }}
      onMouseLeave={(e) => {
        setIsHovered(false);
        props.onMouseLeave?.(e);
      }}
      height={isHovered && !isFlat && !isSmallScreen ? 24 : 0}
      depth={0}
      horizontal="left"
      vertical="top"
      margin={true}
      className={blockWrapperVariants({ size, className })}
      {...props}
    >
      <BlockSides>
        <BlockSideHorizontal className="bg-slate-300" />
        <BlockSideVertical className="bg-slate-200" />
      </BlockSides>
      <BlockContent className={blockWrapperContentVariants({ size })}>
        {content}
      </BlockContent>
    </Block>
  );
}

export { BlockWrapper, blockWrapperVariants, blockWrapperContentVariants };
