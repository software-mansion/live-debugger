import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

import { Badge } from "./badge";
import { Block, BlockContent } from "@/components/ui/block";

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  header: string;
  description: string;
  imageUrl: string;
  badgeText?: string;
  imageSide?: "left" | "right";
}

const TextContent: React.FC<Omit<CardProps, "imageUrl" | "className">> = ({
  header,
  description,
  badgeText,
}) => (
  <div className="flex flex-col justify-start gap-3 md:gap-4 md:pt-4 md:pl-4 lg:gap-5 lg:pt-10 lg:pl-5">
    {badgeText && (
      <>
        <Badge variant="secondary" className="block group-hover:hidden">
          {badgeText}
        </Badge>
        <Badge variant="primary" className="hidden group-hover:block">
          {badgeText}
        </Badge>
      </>
    )}
    <h3 className="text-primary font-aeonik self-stretch text-xl leading-tight font-bold lg:leading-[50px]">
      {header}
    </h3>
    <div className="text-primary font-aeonik text-md self-stretch font-normal">
      {description}
    </div>
  </div>
);

const ImageWrapper: React.FC<{ imageUrl: string; alt: string }> = ({
  imageUrl,
  alt,
}) => (
  <div className="flex items-center justify-center self-stretch">
    <img
      src={imageUrl}
      alt={alt}
      width="200"
      height="150"
      className="h-auto w-full object-cover"
    />
  </div>
);

const BentCorner: React.FC<{ position: "bottom-left" | "bottom-right" }> = ({
  position,
}) => {
  const isBottomLeft = position === "bottom-left";

  return (
    <div
      className={cn(
        "absolute bottom-0",
        isBottomLeft ? "left-0" : "right-0",
        `h-18 w-18 lg:h-25 lg:w-25`,
        "overflow-hidden max-md:hidden",
        "opacity-0 group-hover:opacity-100",
        "transition-opacity duration-300 ease-in-out",
      )}
    >
      <div
        className="absolute h-full w-full bg-white"
        style={{
          clipPath: isBottomLeft
            ? "polygon(0 0, 100% 100%, 0 100%)"
            : "polygon(100% 100%, 100% 0 ,0 100%)",
        }}
      ></div>

      <div
        className="absolute h-full w-full bg-slate-300"
        style={{
          clipPath: isBottomLeft
            ? "polygon(100% 100%, 0 0, 100% 0)"
            : "polygon(100% 0, 0 100%, 0 0)",
        }}
      ></div>
    </div>
  );
};

const Card = React.forwardRef<HTMLDivElement, CardProps>(
  (
    {
      className,
      imageSide = "right",
      header,
      description,
      badgeText,
      imageUrl,
      ...props
    },
    ref,
  ) => {
    const textContent = (
      <TextContent
        header={header}
        description={description}
        badgeText={badgeText}
      />
    );

    const imageContent = <ImageWrapper imageUrl={imageUrl} alt={header} />;

    let bentCornerPosition: "bottom-left" | "bottom-right" | undefined;
    if (imageSide === "right") {
      bentCornerPosition = "bottom-left";
    } else {
      bentCornerPosition = "bottom-right";
    }

    return (
      <Block
        ref={ref}
        height={0}
        depth={0}
        className={cn(
          "group",
          "bg-bg-additional relative flex w-full max-w-[1360px] flex-col items-start justify-center p-6 md:p-8 lg:p-10",
          className,
        )}
        {...props}
      >
        <BlockContent
          className={
            "inline-flex w-full flex-1 flex-col items-start justify-start gap-5"
          }
        >
          <div
            className={
              "grid w-full grid-cols-1 gap-8 md:grid-cols-2 md:gap-20 lg:gap-24"
            }
          >
            <div
              className={cn("order-0", imageSide === "left" && "md:order-last")}
            >
              {textContent}
            </div>

            <div
              className={cn(
                "order-last",
                imageSide === "left" ? "md:order-first" : "md:order-last",
              )}
            >
              {imageContent}
            </div>
          </div>
        </BlockContent>
        {bentCornerPosition && <BentCorner position={bentCornerPosition} />}
      </Block>
    );
  },
);

export { Card };
