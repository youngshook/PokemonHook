###Hook Setup

Eng:

0. Install [iOSOpenDev](http://iosopendev.com) Tools
1. Unzip **Pokemon_unsign.zip**
2. Replace your **embedded.mobileprovision **file to **Payload/pokemongo.app**
3. Update code signing identity in  **Entitlements.plist** and __./Resign.sh__ 
4. Build **PokemonHook** Project (Project added Run Script，need to install [ios-deploy](https://github.com/phonegap/ios-deploy))

中文：

0. 安装 [iOSOpenDev](http://iosopendev.com) Tools
1. 解压 **Pokemon_unsign.zip**
2. 替换 **Payload/pokemongo.app** 中 **embedded.mobileprovision** 文件成自己的
3. 更新 **Entitlements.plist** 与  __./Resign.sh__  文件中的 **XXXXXX** 代码签名
4. 运行 **PokemonHook** 项目 (工程中已添加 __./Resign.sh__ 脚本，且如需要直接安装到手机中，则需 USB 连接手机，即可自动安装)

###Feature

####Eng:

- [X] Direction selection
- [X] Display the current latitude and longitude coordinates
- [X] Display the current position to open GoogleMaps
- [X] Shake hide or display controls


####中文：

- [x] 方向选择
- [x] 显示当前经纬度坐标
- [x] 打开GoogleMaps 显示当前位置
- [x] 摇一摇隐藏或显示控件

![Demo](http://ww3.sinaimg.cn/large/006tNbRwgw1f61onuw0ljj30c30lhq5a.jpg)

