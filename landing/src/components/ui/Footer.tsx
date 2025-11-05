import ContentWrapper from "@/components/ContentWrapper";
import React from "react";
import { cn } from "@/lib/utils";
import { Button } from "./button";

export interface FooterProps extends React.HTMLAttributes<HTMLElement> {}

const logos = [
  {
    name: "Popcorn",
    imageUrl: "/live-debugger/assets/logo-popcorn.svg",
    href: "https://popcorn.swmansion.com/",
  },
  {
    name: "Global Elixir Meetups",
    imageUrl: "/live-debugger/assets/logo-GEM.svg",
    href: "https://globalelixirmeetups.com/",
  },
  {
    name: "Membrane Live",
    imageUrl: "/live-debugger/assets/logo-membrane.svg",
    href: "https://membrane.stream/",
  },
];

const socials = [
  {
    icon: "twitter",
    href: "https://twitter.com/swmansion",
  },
  {
    icon: "facebook",
    href: "https://www.facebook.com/SoftwareMansion/",
  },
  {
    icon: "github",
    href: "https://github.com/software-mansion",
  },
  {
    icon: "instagram",
    href: "https://www.instagram.com/swmansion/",
  },
  {
    icon: "youtube",
    href: "https://www.youtube.com/c/SoftwareMansion",
  },
  {
    icon: "linkedin",
    href: "https://www.linkedin.com/company/software-mansion/",
  },
  {
    icon: "dribble",
    href: "https://dribbble.com/softwaremansion",
  },
  {
    icon: "discord",
    href: "https://discord.com/invite/2gjSqPQc9Q",
  },
];

const Footer = React.forwardRef<HTMLElement, FooterProps>(
  ({ className, ...props }, ref) => {
    return (
      <footer
        id="footer"
        ref={ref}
        className={cn(
          "bg-primary relative bottom-0 w-full overflow-hidden",
          className,
        )}
        {...props}
      >
        <ContentWrapper>
          <div className="mx-auto my-15 flex w-full max-w-[1360px] flex-col items-center justify-between">
            <div className="text-primary-foreground flex flex-col items-center justify-between">
              <div className="z-10 flex flex-col items-center">
                <div className="flex flex-col items-center gap-3">
                  <img
                    src="/live-debugger/assets/logo-swm.svg"
                    alt="Software Mansion"
                    className="h-7 w-auto"
                  />
                  <h1 className="mb-3 text-center text-lg font-bold">
                    We are Software Mansion
                  </h1>
                </div>

                <h2 className="w-full text-center text-xs font-thin md:w-1/2">
                  You might know us from Elixir Stream Week, Global Elixir
                  Meetups, or from projects like Popcorn and Membrane. But
                  that’s not all we do.
                  <br />
                  <br />
                  We help teams build exceptional software - from developer
                  tools to production-ready applications. Let’s talk about how
                  we can support your next project.
                </h2>

                <div className="mt-5 flex flex-row gap-5">
                  <a
                    href="https://swmansion.com/"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <Button variant="secondary" size="sm">
                      <p className="text-medium text-2xs">Learn more</p>
                    </Button>
                  </a>
                </div>
              </div>

              <div className="my-8 flex flex-row gap-x-10">
                {logos.map((logo) => (
                  <a
                    key={logo.name}
                    href={logo.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex h-15 w-auto transform items-center justify-center rounded-full transition-all duration-300 ease-in-out hover:scale-130 hover:opacity-60"
                  >
                    <img
                      src={logo.imageUrl}
                      alt={logo.name}
                      className="h-6 w-auto"
                    />
                  </a>
                ))}
              </div>

              <div className="flex flex-col items-center gap-3">
                <p className="text-2xs font-thin">Check our socials</p>

                <div className="flex items-center">
                  {socials.map(({ icon, href }) => (
                    <a
                      key={href}
                      href={href}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex h-6 w-6 transform items-center justify-center rounded-full transition-all duration-300 ease-in-out hover:scale-150 hover:opacity-60"
                    >
                      <img
                        src={`/live-debugger/assets/${icon}.svg`}
                        className="h-3 w-3"
                        alt={`${icon} icon`}
                        width="16"
                        height="16"
                      />
                    </a>
                  ))}
                </div>
                <p className="text-2xs font-thin">
                  &copy; Software Mansion 2025.
                </p>
              </div>
            </div>
          </div>
        </ContentWrapper>
        <div className="absolute -top-30 -left-30 z-1 sm:-top-40 sm:-left-20 md:-top-50 lg:-top-65 lg:-left-30">
          <img
            src="/live-debugger/assets/Vector.svg"
            alt=""
            className="h-60 w-auto sm:h-80 md:h-100 lg:h-120"
          />
        </div>
        <div className="absolute -right-10 -bottom-25 z-1 sm:-right-40 sm:-bottom-35 md:-right-20 md:-bottom-45 lg:-right-60 lg:-bottom-55">
          <img
            src="/live-debugger/assets/Vector.svg"
            alt=""
            className="h-60 w-auto sm:h-80 md:h-100 lg:h-120"
          />
        </div>
      </footer>
    );
  },
);

Footer.displayName = "Footer";

export { Footer };
