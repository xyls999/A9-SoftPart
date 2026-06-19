/**
 * 通用卡片组件 · 经典鸿蒙浅色风格
 * 动效: 入场上移淡入 + 点击微缩放
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
  @Prop animateIn: boolean = true;
  @State pressed: boolean = false;
  @State appeared: boolean = false;
  @BuilderParam content: () => void;
  onClickAction?: () => void;

  aboutToAppear(): void {
    if (this.animateIn) {
      setTimeout(() => { this.appeared = true; }, 30);
    } else {
      this.appeared = true;
    }
  }

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
    .opacity(this.appeared ? 1 : 0)
    .translate({ y: this.appeared ? 0 : 14 })
    .animation({ duration: 300, curve: Curve.EaseOut })
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
