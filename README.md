# Xr_Preview_Tools
    Xr_Preview_Tools是一个生成拍屏预览的插件，使用插件生成拍屏预览的文件大小会比Max拍出来的小很多倍,并且可以设置后台生成拍屏预览,不会占用当前Max,可以继续制作等待完成即可.
使用方法：
先调整一个想要拍屏使用的构图.
点击 获取视图 , 上方会出现当前获取到的视图.
默认勾选会使用当前文件命名来命名拍屏文件.不勾选 则可以自定义输入拍屏命名.
拍屏文件默认会存放在当前文件所在的文件夹内. 不勾选 使用文件路径 则可以点击文件夹图标进行自定义选择要保存的位置.
批量拍屏 勾选会把当前文件所在文件夹内所有Max文件进行拍屏. 拍屏过程中多次按ESC则可以取消中断.
后台拍屏 会打开一个新的Max进行拍屏,不会占用当前Max,可以继续做自己的事情,拍屏完成会有弹窗提示.（注意：勾选后台拍屏新开的Max不要最小化,否则拍屏视频会是全黑屏.）
设置 如果使用当前窗口进行拍屏(不勾选后台拍屏)使用,调用的Max自带的预览设置,会对拍屏效果做更改,后台拍屏则不需要更改.拍屏逻辑方法不一样.
都设置好后点击 运行 就行了~ 完成后会有弹窗 询问是否打开当前拍屏所在文件夹可以进行快速打开操作.



     插件运行逻辑：使用Max自带的拍屏先生成视频文件,然后调用 FFmpeg 进行转码,可以保证最清晰的情况容量占用最小,几乎都是以KB为单位,除非时间很长的文件,完美解决Max自带的拍屏都是几百兆甚至一个G的问题~
     
