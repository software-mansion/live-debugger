// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
const colors = require('tailwindcss/colors');
const plugin = require('tailwindcss/plugin');
const fs = require('fs');
const path = require('path');

module.exports = {
  darkMode: 'class',
  content: ['./js/**/*.js', '../../lib/**/*.ex'],
  theme: {
    extend: {
      boxShadow: { custom: '0px 2px 4px 0px rgba(0, 26, 114, 0.05)' },
      colors: {
        'main-bg': 'var(--main-bg)',
        'primary-text': 'var(--primary-text)',
        'secondary-text': 'var(--secondary-text)',
        'accent-text': 'var(--accent-text)',
        'link-primary': 'var(--link-primary)',
        'link-primary-hover': 'var(--link-primary-hover)',
        'default-border': 'var(--default-border)',
        'surface-0-bg': 'var(--surface-0-bg)',
        'surface-0-bg-hover': 'var(--surface-0-bg-hover)',
        'surface-1-bg': 'var(--surface-1-bg)',
        'surface-1-bg-hover': 'var(--surface-1-bg-hover)',
        'surface-2-bg': 'var(--surface-2-bg)',
        'surface-2-bg-hover': 'var(--surface-2-bg-hover)',
        'ui-surface': 'var(--ui-surface)',
        'ui-muted': 'var(--ui-muted)',
        'ui-accent': 'var(--ui-accent)',
        'navbar-bg': 'var(--navbar-bg)',
        'navbar-border': 'var(--navbar-border)',
        'navbar-icon': 'var(--navbar-icon)',
        'navbar-icon-bg-hover': 'var(--navbar-icon-bg-hover)',
        'navbar-icon-hover': 'var(--navbar-icon-hover)',
        'navbar-logo': 'var(--navbar-logo)',
        'button-primary-bg': 'var(--button-primary-bg)',
        'button-primary-bg-hover': 'var(--button-primary-bg-hover)',
        'button-primary-content': 'var(--button-primary-content)',
        'button-primary-content-hover': 'var(--button-primary-content-hover)',
        'button-secondary-bg': 'var(--button-secondary-bg)',
        'button-secondary-bg-hover': 'var(--button-secondary-bg-hover)',
        'button-secondary-border': 'var(--button-secondary-border)',
        'button-secondary-border-hover': 'var(--button-secondary-border-hover)',
        'button-secondary-content': 'var(--button-secondary-content)',
        'button-secondary-content-hover':
          'var(--button-secondary-content-hover)',
        'tooltip-text': 'var(--tooltip-text)',
        'tooltip-bg': 'var(--tooltip-bg)',
        'accent-icon': 'var(--accent-icon)',
        'sidebar-bg': 'var(--sidebar-bg)',
        'code-1': 'var(--code-1)',
        'code-2': 'var(--code-2)',
        'code-3': 'var(--code-3)',
        'code-4': 'var(--code-4)',
        'error-bg': 'var(--error-bg)',
        'error-border': 'var(--error-border)',
        'error-icon': 'var(--error-icon)',
        'error-text': 'var(--error-text)',
        'warning-text': 'var(--warning-text)',
        'info-bg': 'var(--info-bg)',
        'info-border': 'var(--info-border)',
        'info-icon': 'var(--info-icon)',
        'info-text': 'var(--info-text)',
        'diff-border': 'var(--diff-border)',
        'diff-negative-bg': 'var(--diff-negative-bg)',
        'diff-positive-bg': 'var(--diff-positive-bg)',
      },
      screens: { xs: '380px' },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        code: [
          'ui-monospace',
          'SFMono-Regular',
          'SF Mono',
          'Menlo',
          'Consolas',
          'Liberation Mono',
          'monospace',
        ],
      },
      fontSize: { '3xs': ['10px', '13px'], '2xs': ['11px', '20px'] },
      keyframes: {
        fadeOut: {
          '0%': { opacity: '1', transform: 'scale(1)' },
          '100%': { opacity: '0', transform: 'scale(0.95)' },
        },
        fadeOutMobile: {
          '0%': { opacity: '1', transform: 'translateY(0)' },
          '100%': { opacity: '0', transform: 'translateY(1rem)' },
        },
        fadeIn: {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        fadeInMobile: {
          '0%': { opacity: '0', transform: 'translateY(1rem)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        diffPulse: {
          '0%': {
            backgroundColor: 'var(--diff-pulse-bg)',
            color: 'var(--diff-pulse-text)',
          },
          '100%': { backgroundColor: '', color: '' },
        },
      },
      animation: {
        'fade-out': 'fadeOut 200ms ease-out forwards',
        'fade-out-mobile': 'fadeOutMobile 200ms ease-out forwards',
        'fade-in': 'fadeIn 100ms ease-in forwards',
        'fade-in-mobile': 'fadeInMobile 100ms ease-in forwards',
        'diff-pulse': 'diffPulse 500ms ease-out',
      },
    },
  },
  variants: {
    extend: {
      animationFillMode: ['forwards'],
    },
  },
  plugins: [
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
