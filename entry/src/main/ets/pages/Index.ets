/**
 * 应用主入口 · 经典鸿蒙浅色
 * 底部 Tab 栏 + 中间 AI 圆形入口
 */
import { HomePage } from './HomePage';
import { MonitorPage } from './MonitorPage';
import { HistoryPage } from './HistoryPage';
import { ChatPage } from './ChatPage';
import { MinePage } from './MinePage';
import { AppColors } from '../theme/Colors';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  @Builder
  pageContent() {
    if (this.currentIndex === 0) {
      HomePage()
    } else if (this.currentIndex === 1) {
      MonitorPage()
    } else if (this.currentIndex === 2) {
      HistoryPage()
    } else if (this.currentIndex === 3) {
      ChatPage()
    } else {
      MinePage()
    }
  }

  @Builder
  tabItem(index: number, icon: Resource, label: string, isActive: boolean) {
    Column({ space: 3 }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([isActive ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY])
        .opacity(isActive ? 1 : 0.6)
      Text(label)
        .fontSize(10)
        .fontColor(isActive ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
        .fontWeight(isActive ? FontWeight.Medium : FontWeight.Regular)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.currentIndex = index; })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.BG_PAGE)

      Column() {
        this.pageContent()
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 80 })

      // 底部 Tab 栏
      Row() {
        Column() { this.tabItem(0, $r('sys.symbol.house'), '首页', this.currentIndex === 0) }
          .layoutWeight(1).height('100%')
        Column() { this.tabItem(1, $r('sys.symbol.eye_viewfinder'), '监控', this.currentIndex === 1) }
          .layoutWeight(1).height('100%')
        Column().layoutWeight(1).height('100%')
        Column() { this.tabItem(2, $r('sys.symbol.clock_fill'), '历史', this.currentIndex === 2) }
          .layoutWeight(1).height('100%')
        Column() { this.tabItem(4, $r('sys.symbol.person_fill'), '我的', this.currentIndex === 4) }
          .layoutWeight(1).height('100%')
      }
      .width('100%')
      .height(56)
      .backgroundColor(AppColors.BG_CARD)
      .border({ width: { top: 0.5 }, color: AppColors.HAIRLINE })
      .shadow(ShadowStyle.OUTER_DEFAULT_MD)

      // 中间 AI 圆形入口
      Column() {
        Column() {
          SymbolGlyph($r('sys.symbol.mic_fill'))
            .fontSize(24)
            .fontColor([AppColors.TEXT_INVERSE])
        }
        .width(52).height(52)
        .borderRadius(26)
        .backgroundColor(AppColors.PRIMARY)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .shadow({ radius: 12, color: '#33007DFF', offsetX: 0, offsetY: 4 })
        .scale({ x: this.currentIndex === 3 ? 1.08 : 1, y: this.currentIndex === 3 ? 1.08 : 1 })
        .animation({ duration: 200, curve: Curve.EaseInOut })
        .onClick(() => { this.currentIndex = 3; })
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height('100%')
  }
}
