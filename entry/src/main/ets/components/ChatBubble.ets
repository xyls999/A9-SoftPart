/**
 * 对话气泡 · 优化版
 * 用户气泡: 右对齐，鸿蒙蓝底白字
 * 助手气泡: 左对齐，白底深字 + 头像 + 细边框
 * 优化: 更精致的圆角、间距、头像、打字光标
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

      // 助手头像
      if (this.message.role === ChatRole.ASSISTANT) {
        Column() {
          SymbolGlyph($r('sys.symbol.Celia'))
            .fontSize(16)
            .fontColor([AppColors.PRIMARY])
        }
        .width(30).height(30)
        .borderRadius(15)
        .backgroundColor(AppColors.PRIMARY_BG)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 2 })
      }

      // 气泡内容
      Text(this.message.content + (this.message.isStreaming ? '▍' : ''))
        .fontSize(AppFont.SIZE_BODY)
        .lineHeight(22)
        .fontColor(this.message.role === ChatRole.USER ? AppColors.TEXT_INVERSE : AppColors.TEXT_PRIMARY)
        .padding({
          left: AppSpace.BASE, right: AppSpace.BASE,
          top: AppSpace.SM + 2, bottom: AppSpace.SM + 2
        })
        .borderRadius({
          topLeft: this.message.role === ChatRole.ASSISTANT ? 4 : AppSpace.RADIUS_BASE,
          topRight: this.message.role === ChatRole.USER ? 4 : AppSpace.RADIUS_BASE,
          bottomLeft: AppSpace.RADIUS_BASE,
          bottomRight: AppSpace.RADIUS_BASE
        })
        .backgroundColor(this.message.role === ChatRole.USER ? AppColors.PRIMARY : AppColors.BG_CARD)
        .border(this.message.role === ChatRole.ASSISTANT ? { width: 0.5, color: AppColors.HAIRLINE } : { width: 0, color: '#00000000' })
        .constraintSize({ maxWidth: '72%' })
        .shadow(this.message.role === ChatRole.USER ? {
          radius: 8, color: '#0D007DFF', offsetX: 0, offsetY: 2
        } : { radius: 0, color: '#00000000', offsetX: 0, offsetY: 0 })

      if (this.message.role === ChatRole.ASSISTANT) {
        Blank()
      }
    }
    .width('100%')
    .padding({
      left: AppSpace.PAGE_PADDING, right: AppSpace.PAGE_PADDING
    })
    .alignItems(VerticalAlign.Top)
  }
}
