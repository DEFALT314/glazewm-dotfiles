# Bar fonts

The bar ships its own fonts, so it looks the same whatever is installed:

- `JetBrainsMono-Variable-subset.woff2`: the variable
  [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) (weights
  100-800), cut down to Basic Latin. The weight is `--text-weight` in
  `../styles.css`.
- `JetBrainsMonoNerdFont-icons-subset.woff2`: only the icons the bar uses,
  taken from [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts)
  Regular.

To regenerate them, for example after adding an icon (append its code
point to `--unicodes`):

```sh
pyftsubset 'JetBrainsMono[wght].ttf' --unicodes="U+0020-007E" \
  --layout-features='*' --flavor=woff2 \
  --output-file=JetBrainsMono-Variable-subset.woff2

pyftsubset JetBrainsMonoNerdFont-Regular.ttf \
  --unicodes="U+EA71,U+EAB0,U+F025,U+F028,U+F240-F244,U+F0084,U+F02CA,U+F0425,U+F057E,U+F0580,U+F0709,U+F075F,U+F0904,U+F0906" \
  --flavor=woff2 --output-file=JetBrainsMonoNerdFont-icons-subset.woff2
```

JetBrains Mono is licensed under the [SIL Open Font License 1.1](OFL.txt).
The icons come from Nerd Fonts' bundled sets: Font Awesome (OFL 1.1),
Material Design Icons (Apache 2.0) and Codicons (CC BY 4.0).
