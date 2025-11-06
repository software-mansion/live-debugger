import { cn } from "@/lib/utils";

export interface BlockProps extends React.ComponentProps<"div"> {
  /**
   * Depth of the block (in pixels). Keeps the front face position static.
   * @default 0
   * @see `block-d-*`
   */
  depth?: number;
  /**
   * Height of the block (in pixels). Makes the front face position dynamic.
   * @default 0
   * @see `block-h-*`
   */
  height?: number;
  /**
   * Horizontal side the block is leaning towards.
   * @default "left"
   */
  horizontal?: "left" | "right";
  /**
   * Adds `depth`-sized margins to the sides of the block.
   * @default false
   */
  margin?: boolean;
  /**
   * Maximum depth of the block (in pixels). Useful when trying to avoid
   * layout shifts when animating `depth` with `margin: true`.
   * @default 0
   * @see `block-max-d-*`
   */
  maximumDepth?: number;
  /**
   * Maximum height of the block (in pixels). Useful when trying to avoid
   * layout shifts when animating `height` with `margin: true`.
   * @default 0
   * @see `block-max-h-*`
   */
  maximumHeight?: number;
  /**
   * Adds transitions to block. Disabling transitions could be useful when
   * working with animation libraries, while enabling them could be useful
   * when working with Tailwind CSS hover, focus and other states.
   * @default true
   */
  transitions?: boolean;
  /**
   * Vertical side the block is leaning towards.
   * @default "top"
   */
  vertical?: "bottom" | "top";
}

export type BlockContentProps = React.ComponentProps<"div">;

export const Block = ({
  className,
  depth,
  height,
  horizontal = "left",
  margin = false,
  maximumDepth,
  maximumHeight,
  style,
  transitions = true,
  vertical = "top",
  ...props
}: BlockProps) => (
  <div
    className={cn(
      "group relative isolate flex flex-col before:absolute before:inset-0 before:z-[-1]",
      margin &&
        vertical === "bottom" &&
        "mt-(--block-maximum-depth) mb-(--block-maximum-height) before:-top-(--block-maximum-depth,0px) before:-bottom-(--block-maximum-height,0px)",
      margin &&
        horizontal === "left" &&
        "mr-(--block-maximum-depth) ml-(--block-maximum-height) before:-right-(--block-maximum-depth,0px) before:-left-(--block-maximum-height,0px)",
      margin &&
        horizontal === "right" &&
        "mr-(--block-maximum-height) ml-(--block-maximum-depth) before:-right-(--block-maximum-height,0px) before:-left-(--block-maximum-depth,0px)",
      margin &&
        vertical === "top" &&
        "mt-(--block-maximum-height) mb-(--block-maximum-depth) before:-top-(--block-maximum-height,0px) before:-bottom-(--block-maximum-depth,0px)",
      className,
    )}
    data-coefficient={
      (horizontal === "left" ? -1 : 1) * (vertical === "top" ? -1 : 1)
    }
    data-horizontal={horizontal}
    data-transitions={transitions}
    data-vertical={vertical}
    style={{
      ...style,
      ["--block-horizontal" as keyof React.CSSProperties]:
        horizontal === "left" ? -1 : 1,
      ["--block-vertical" as keyof React.CSSProperties]:
        vertical === "top" ? -1 : 1,
      ...(typeof depth !== "undefined"
        ? {
            ["--block-depth" as keyof React.CSSProperties]: `${Math.max(depth, 0)}px`,
          }
        : {}),
      ...(typeof height !== "undefined"
        ? {
            ["--block-height" as keyof React.CSSProperties]: `${Math.max(height, 0)}px`,
          }
        : {}),
      ...(typeof maximumDepth !== "undefined"
        ? {
            ["--block-maximum-depth" as keyof React.CSSProperties]: `${Math.max(maximumDepth, 0)}px`,
          }
        : {}),
      ...(typeof maximumHeight !== "undefined"
        ? {
            ["--block-maximum-height" as keyof React.CSSProperties]: `${Math.max(maximumHeight, 0)}px`,
          }
        : {}),
    }}
    {...props}
  />
);

export const BlockContent = ({ className, ...props }: BlockContentProps) => (
  <div
    className={cn(
      "grow translate-x-[calc(var(--block-horizontal)*var(--block-height))] translate-y-[calc(var(--block-vertical)*var(--block-height))] group-data-[transitions=true]:transition-all",
      className,
    )}
    {...props}
  />
);

export const BlockSideHorizontal = ({
  className,
  ...props
}: React.ComponentProps<"div">) => (
  <div
    className={cn(
      "group-data-[coefficient=-1]:block-clip-h-45 group-data-[coefficient=1]:-block-clip-h-45 absolute h-[calc(100%+var(--block-depth)+var(--block-height))] w-[calc(var(--block-depth)+var(--block-height))] group-data-[horizontal=left]:left-[calc(100%-var(--block-height))] group-data-[horizontal=right]:right-[calc(100%-var(--block-height))] group-data-[transitions=true]:transition-all group-data-[vertical=bottom]:-top-(--block-depth) group-data-[vertical=top]:-top-(--block-height)",
      className,
    )}
    {...props}
  />
);

export const BlockSideVertical = ({
  className,
  ...props
}: React.ComponentProps<"div">) => (
  <div
    className={cn(
      "group-data-[coefficient=-1]:block-clip-v-45 group-data-[coefficient=1]:-block-clip-v-45 absolute h-[calc(var(--block-depth)+var(--block-height))] w-[calc(100%+var(--block-depth)+var(--block-height))] group-data-[horizontal=left]:-left-(--block-height) group-data-[horizontal=right]:-left-(--block-depth) group-data-[transitions=true]:transition-all group-data-[vertical=bottom]:-top-(--block-depth) group-data-[vertical=top]:top-[calc(100%-var(--block-height))]",
      className,
    )}
    {...props}
  />
);

export const BlockSides = ({
  "aria-hidden": ariaHidden = true,
  className,
  ...props
}: React.ComponentProps<"div">) => (
  <div
    aria-hidden={ariaHidden}
    className={cn("absolute inset-0 z-[-1]", className)}
    {...props}
  />
);
