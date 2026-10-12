# Bar font

`JetBrainsMonoNerdFont-Regular-subset.woff2` is the Regular face of
[JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts), cut
down to Basic Latin and the icons the bar uses. Shipping it with the widget
means Windows can't render the bar in another installed weight.

To regenerate it after adding an icon, append the icon's code point to
`--unicodes`:

```sh
pyftsubset JetBrainsMonoNerdFont-Regular.ttf \
  --unicodes="U+0020-007E,U+EA71,U+EAB0,U+F025,U+F028,U+F240-F244,U+F0084,U+F02CA,U+F0425,U+F057E,U+F0580,U+F0709,U+F075F,U+F0904,U+F0906" \
  --layout-features='*' --flavor=woff2 \
  --output-file=JetBrainsMonoNerdFont-Regular-subset.woff2
```

JetBrains Mono is licensed under the [SIL Open Font License 1.1](OFL.txt).
The icons come from Nerd Fonts' bundled sets: Font Awesome (OFL 1.1),
Material Design Icons (Apache 2.0) and Codicons (CC BY 4.0).
