/**
 * 对话气泡 · 经典鸿蒙浅色
 * 用户气泡: 右对齐，鸿蒙蓝底白字
 * 助手气泡: 左对齐，浅灰底深字
 */
import { ChatMessage, ChatRole } from '../api/types';
import { AppColors } from '../theme/Colors';
import { AppSpace } from '../theme/Spacing';
import { AppFont } from '../theme/Typography';

@Component
export struct ChatBubble {
  @Prop message: ChatMessage;

  build() {
    Row() {
      if (this.message.role === ChatRole.USER) {
        Blank()
      }
      Row({ space: AppSpace.SM }) {
        if (this.message.role === ChatRole.ASSISTANT) {
          Column() {
            SymbolGlyph($r('sys.symbol.Celia'))
              .fontSize(18)
              .fontColor([AppColors.PRIMARY])
          }
          .width(32).height(32)
          .borderRadius(16)
          .backgroundColor(AppColors.PRIMARY_BG)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        Text(this.message.content + (this.message.isStreaming ? '▍' : ''))
          .fontSize(AppFont.SIZE_BODY)
          .fontColor(this.message.role === ChatRole.USER ? AppColors.TEXT_INVERSE : AppColors.TEXT_PRIMARY)
          .padding({ left: AppSpace.BASE, right: AppSpace.BASE, top: AppSpace.SM, bottom: AppSpace.SM })
          .borderRadius(AppSpace.RADIUS_BASE)
          .backgroundColor(this.message.role === ChatRole.USER ? AppColors.PRIMARY : AppColors.BG_CARD)
          .border(this.message.role === ChatRole.ASSISTANT ? { width: 0.5, color: AppColors.HAIRLINE } : { width: 0, color: '#00000000' })
          .constraintSize({ maxWidth: '76%' })
      }
      .alignItems(VerticalAlign.Top)
      .layoutWeight(1)
      .justifyContent(this.message.role === ChatRole.USER ? FlexAlign.End : FlexAlign.Start)

      if (this.message.role === ChatRole.ASSISTANT) {
        Blank()
      }
    }
    .width('100%')
    .padding({ left: AppSpace.PAGE_PADDING, right: AppSpace.PAGE_PADDING })
  }
}
