// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
const colors = require('tailwindcss/colors');
const plugin = require('tailwindcss/plugin');
const fs = require('fs');
const path = require('path');

module.exports = {
  darkMode: 'selector',
  content: ['./js/**/*.js', '../lib/**/*.ex'],
  safelist: [
    {
      pattern:
        /(text|bg|border)-(primary|secondary|success|danger|warning|info|gray)-(50|100|200|300|400|500|600|700|800|900|950)/,
      variants: ['hover', 'focus', 'active', 'md', 'lg', 'sm'],
    },
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#F6F4FE',
          100: '#EDEBFC',
          200: '#DFDAFA',
          300: '#C7BDF5',
          400: '#A997EE',
          500: '#8D6DE5',
          600: '#7B4ED9',
          700: '#6B3CC5',
          800: '#5A31A6',
          900: '#4C2B8A',
          950: '#2E195C',
        },
        secondary: colors.slate,
        success: colors.green,
        danger: colors.red,
        warning: colors.yellow,
        info: colors.sky,
        gray: colors.gray,
      },
      screens: { xs: '380px' },
      fontFamily: { sans: ['Inter', 'sans-serif'], mono: ['DM Mono', 'serif'] },
      fontSize: {
        '3xs': ['10px', '13px'],
        '2xs': ['11px', '20px'],
        sm: ['13px', '20px'],
        base: ['15px', '20px'],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    plugin(({ addVariant }) =>
      addVariant('phx-click-loading', [
        '&.phx-click-loading',
        '.phx-click-loading &',
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-submit-loading', [
        '&.phx-submit-loading',
        '.phx-submit-loading &',
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-change-loading', [
        '&.phx-change-loading',
        '.phx-change-loading &',
      ])
    ),
    // Plugin for fullscreen backdrop
    plugin(function ({ addVariant, e }) {
      addVariant('backdrop', ({ modifySelectors, separator }) => {
        modifySelectors(({ className }) => {
          return `.${e(`backdrop${separator}${className}`)}::backdrop`;
        });
      });
    }),
    // Plugin for adding custom icons
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, './icons');
      let values = {};

      fs.readdirSync(iconsDir).forEach((file) => {
        let name = path.basename(file, '.svg');
        values[name] = { name, fullPath: path.join(iconsDir, file) };
      });
      matchComponents(
        {
          icon: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, '');
            let size = theme('spacing.6');
            if (name.endsWith('-mini')) {
              size = theme('spacing.5');
            } else if (name.endsWith('-micro')) {
              size = theme('spacing.4');
            }
            return {
              [`--icon-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              '-webkit-mask': `var(--icon-${name})`,
              mask: `var(--icon-${name})`,
              'mask-repeat': 'no-repeat',
              'background-color': 'currentColor',
              'vertical-align': 'middle',
              display: 'inline-block',
              width: size,
              height: size,
            };
          },
        },
        { values }
      );
    }),
  ],
};
