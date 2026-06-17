/**
 * 通用卡片组件 · 经典鸿蒙浅色风格
 * 取代旧 GlassCard：白底 + 微弱阴影 + 克制圆角
 * 动效: 仅点击时微缩放（无呼吸光/扫光）
 *
 * 用法:
 *   AppCard({ innerPadding: 16 }) {
 *     // 卡片内容
 *   }
 */
import { AppColors } from '../theme/Colors';
import { AppSpace } from '../theme/Spacing';
import { TapEffect } from '../theme/Effects';

@Component
export struct AppCard {
  @Prop innerPadding: number = AppSpace.BASE;
  @Prop cornerRadius: number = AppSpace.RADIUS_CARD;
  @Prop bgColor: string = AppColors.BG_CARD;
  @Prop clickable: boolean = true;
  @State pressed: boolean = false;
  @BuilderParam content: () => void;
  onClickAction?: () => void;

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.innerPadding)
    .borderRadius(this.cornerRadius)
    .backgroundColor(this.pressed ? AppColors.BG_CARD_TAP : this.bgColor)
    .border({ width: 0.5, color: AppColors.HAIRLINE })
    .shadow(this.pressed ? ShadowStyle.OUTER_DEFAULT_XS : ShadowStyle.OUTER_DEFAULT_SM)
    .scale({
      x: this.pressed ? TapEffect.PRESSED : TapEffect.NORMAL,
      y: this.pressed ? TapEffect.PRESSED : TapEffect.NORMAL
    })
    .animation({ duration: TapEffect.DURATION, curve: Curve.EaseInOut })
    .onClick(() => { if (this.onClickAction) this.onClickAction(); })
    .onTouch((e: TouchEvent) => {
      if (!this.clickable) return;
      if (e.type === TouchType.Down) {
        this.pressed = true;
      } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
  }
}
