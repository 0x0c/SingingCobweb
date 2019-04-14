# 蜘蛛の巣

## Dependencies
- [controlP5](http://www.sojamo.de/libraries/controlP5/)
- [minim](http://code.compartmental.net/minim/)

メニューバーの`Sketch > ImportLibrary > addLibrary`からインストールする。

## 楽曲の変更

1. `player.pde`と同じディレクトリにある`mp3`フォルダ以下に`mp3` ファイルを配置する
2. `player.pde`の`String[] filenames`という変数に楽曲のファイル名を列挙する

列挙できる音源は8つまで。8つ以下、以上の場合の動作は確認していない。