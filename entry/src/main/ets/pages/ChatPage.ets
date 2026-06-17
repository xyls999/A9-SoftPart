/**
 * ChatFlow 对话页 · 经典鸿蒙浅色
 */
import { ChatBubble } from '../components/ChatBubble';
import { ChatApi } from '../api/chatApi';
import { ChatMessage, ChatRole } from '../api/types';
import { AppColors } from '../theme/Colors';
import { AppSpace } from '../theme/Spacing';
import { AppFont } from '../theme/Typography';

@Component
export struct ChatPage {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isResponding: boolean = false;
  @State isListening: boolean = false;
  private scroller: Scroller = new Scroller();
  private msgId: number = 1;

  aboutToAppear(): void {
    this.messages = [{
      id: 'msg_0',
      role: ChatRole.ASSISTANT,
      content: ChatApi.getWelcome(),
      timestamp: Date.now()
    }];
  }

  scrollToBottom(): void {
    setTimeout((): void => { this.scroller.scrollEdge(Edge.Bottom); }, 50);
  }

  async send(): Promise<void> {
    const text = this.inputText.trim();
    if (!text || this.isResponding) return;

    const userMsg: ChatMessage = {
      id: `msg_${this.msgId++}`,
      role: ChatRole.USER,
      content: text,
      timestamp: Date.now()
    };
    this.messages = this.messages.concat([userMsg]);
    this.inputText = '';
    this.scrollToBottom();

    const assistantId = `msg_${this.msgId++}`;
    this.isResponding = true;
    const placeholder: ChatMessage = {
      id: assistantId,
      role: ChatRole.ASSISTANT,
      content: '',
      timestamp: Date.now(),
      isStreaming: true
    };
    this.messages = this.messages.concat([placeholder]);
    this.scrollToBottom();

    await ChatApi.sendStream(
      this.messages.slice(0, -1),
      (partial: string) => {
        this.messages = this.messages.map((m: ChatMessage): ChatMessage =>
          m.id === assistantId ? {
            id: m.id, role: m.role, content: partial, timestamp: m.timestamp, isStreaming: true
          } : m
        );
        this.scrollToBottom();
      },
      (finalMsg: ChatMessage) => {
        this.messages = this.messages.map((m: ChatMessage): ChatMessage =>
          m.id === assistantId ? {
            id: assistantId, role: finalMsg.role, content: finalMsg.content,
            timestamp: finalMsg.timestamp, isStreaming: false
          } : m
        );
        this.isResponding = false;
        this.scrollToBottom();
      }
    );
  }

  async startVoice(): Promise<void> {
    if (this.isListening) return;
    this.isListening = true;
    const text = await ChatApi.voiceToText('');
    this.isListening = false;
    this.inputText = text;
  }

  build() {
    Column() {
      // 顶部标题栏（白底）
      Row({ space: AppSpace.SM }) {
        SymbolGlyph($r('sys.symbol.mic_fill'))
          .fontSize(22)
          .fontColor([AppColors.PRIMARY])
        Column({ space: 2 }) {
          Text('智能助手')
            .fontSize(AppFont.SIZE_TITLE)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
          Text(this.isResponding ? '正在回复...' : '在线 · 随时为你服务')
            .fontSize(AppFont.SIZE_CAPTION)
            .fontColor(this.isResponding ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: AppSpace.PAGE_PADDING, right: AppSpace.PAGE_PADDING, top: 44, bottom: AppSpace.MD })
      .backgroundColor(AppColors.BG_CARD)

      // 消息流
      Scroll(this.scroller) {
        Column({ space: AppSpace.MD }) {
          ForEach(this.messages, (m: ChatMessage) => {
            ChatBubble({ message: m })
          }, (m: ChatMessage) => m.id)
          Column().height(AppSpace.LG)
        }
        .width('100%')
        .padding({ top: AppSpace.SM, bottom: 80 })
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(AppColors.BG_PAGE)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.TopStart)

      // 底部输入栏（白底）
      Row({ space: AppSpace.SM }) {
        Column() {
          SymbolGlyph(this.isListening ? $r('sys.symbol.mic_badge_recordingtape') : $r('sys.symbol.mic_fill'))
            .fontSize(20)
            .fontColor([this.isListening ? AppColors.DANGER : AppColors.TEXT_SECONDARY])
        }
        .width(40).height(40)
        .borderRadius(20)
        .backgroundColor(this.isListening ? '#FCE8E5' : AppColors.BG_INPUT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => this.startVoice())

        TextInput({ text: this.inputText, placeholder: this.isListening ? '正在聆听...' : '输入消息或点击语音' })
          .layoutWeight(1)
          .height(40)
          .fontSize(AppFont.SIZE_BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .placeholderColor(AppColors.TEXT_TERTIARY)
          .placeholderFont({ size: AppFont.SIZE_BODY })
          .borderRadius(20)
          .backgroundColor(AppColors.BG_INPUT)
          .padding({ left: AppSpace.BASE, right: AppSpace.BASE })
          .onChange((v: string) => { this.inputText = v; })
          .onSubmit(() => this.send())

        Column() {
          SymbolGlyph($r('sys.symbol.paperplane_fill'))
            .fontSize(16)
            .fontColor([AppColors.TEXT_INVERSE])
        }
        .width(40).height(40)
        .borderRadius(20)
        .backgroundColor(this.inputText.trim() ? AppColors.PRIMARY : AppColors.BG_INPUT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => this.send())
      }
      .width('100%')
      .padding({ left: AppSpace.PAGE_PADDING, right: AppSpace.PAGE_PADDING, top: AppSpace.SM, bottom: AppSpace.SM })
      .backgroundColor(AppColors.BG_CARD)
      .border({ width: { top: 0.5 }, color: AppColors.HAIRLINE })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }
}
