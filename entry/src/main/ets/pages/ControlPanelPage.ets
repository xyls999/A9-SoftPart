/**
 * 明日家居主控：智能对话 + 数据管理。
 * 保留原有 ChatApi，主题和页面切换仅改变前端表现。
 */
import { ChatApi } from '../api/chatApi';
import { ChartData, ChatMessage, ChatRole } from '../api/types';
import { ChatChartPanel } from '../components/ChatChartPanel';
import { HistoryPage } from './HistoryPage';
import { TacticalMotion, TacticalTheme } from '../theme/TacticalTheme';

@Component
export struct ControlPanelPage {
  @State activePage: number = 0;
  @State isDark: boolean = true;
  @State inputText: string = '';
  @State messages: ChatMessage[] = [];
  @State isResponding: boolean = false;
  @State isListening: boolean = false;
  @State pressedKey: string = '';
  @State contentVisible: boolean = true;
  @State booting: boolean = true;
  @State bootVisible: boolean = true;
  @State bootProgress: number = 0;
  @State bootStage: number = 0;
  @State themeSwitching: boolean = false;
  @State themeProgress: number = 0;
  @State themeStage: number = 0;
  @State targetDark: boolean = false;
  @State sourceDark: boolean = true;
  @State themeGradientAngle: number = 34;
  @State themeSweep: number = 580;
  @State themeClosing: boolean = false;
  @State pageDirection: number = 1;
  @State pageSwitching: boolean = false;
  @State switchProgress: number = 0;
  @State switchStage: number = 0;
  @State targetPage: number = 0;
  @State switchClosing: boolean = false;
  @State motionTick: number = 0;
  @State thinkingTick: number = 0;
  @State isThinking: boolean = false;
  @State thinkingProgress: number = 0;
  @State thinkingFinishing: boolean = false;
  @State revealingMessageId: string = '';
  @State replyVisible: boolean = true;
  @State assistantReveal: number = 0;
  private msgId: number = 1;
  private motionRunId: number = 0;
  private thinkingRunId: number = 0;
  private chatScroller: Scroller = new Scroller();
  private timers: number[] = [];

  aboutToAppear(): void {
    this.messages = [{
      id: 'msg_0',
      role: ChatRole.ASSISTANT,
      content: '你好，我是明日家居。系统已就绪。',
      timestamp: Date.now()
    }];
    this.startMotionLoop();
    this.startBootSequence();
  }

  aboutToDisappear(): void {
    for (const timer of this.timers) clearTimeout(timer);
    this.timers = [];
  }

  private page(): string { return TacticalTheme.page(this.isDark); }
  private panel(): string { return TacticalTheme.panel(this.isDark); }
  private raised(): string { return TacticalTheme.panelRaised(this.isDark); }
  private input(): string { return TacticalTheme.input(this.isDark); }
  private text(): string { return TacticalTheme.text(this.isDark); }
  private secondary(): string { return TacticalTheme.textSecondary(this.isDark); }
  private muted(): string { return TacticalTheme.textMuted(this.isDark); }
  private frameTone(): string { return TacticalTheme.border(this.isDark); }
  private accent(): string { return TacticalTheme.accent(this.isDark); }
  private brandInk(): string { return this.isDark ? '#0B1B25' : '#173027'; }
  private brandAccent(): string { return this.isDark ? '#8FD3EE' : '#4D8B70'; }
  private brandGhost(): string { return this.isDark ? '#D6EDF7' : '#DCEDE4'; }

  private bootLabel(): string {
    if (this.bootStage <= 0) return '唤醒本地服务';
    if (this.bootStage === 1) return '载入家居模块';
    if (this.bootStage === 2) return '建立数据连接';
    if (this.bootStage === 3) return '整理界面层级';
    return '系统准备完成';
  }

  private switchLabel(): string {
    if (this.switchStage <= 0) return '准备切换页面';
    if (this.switchStage === 1) return '收拢当前内容';
    if (this.switchStage === 2) return '整理页面结构';
    if (this.switchStage === 3) return '展开目标页面';
    return '页面切换完成';
  }

  private targetLabel(): string {
    return this.targetPage === 0 ? '明日家居' : '数据管理';
  }

  private themeLabel(): string {
    if (this.themeStage <= 0) return '准备调整光影';
    if (this.themeStage === 1) return '收起当前色调';
    if (this.themeStage === 2) return '转换明暗层级';
    if (this.themeStage === 3) return '展开新的色调';
    return '光影切换完成';
  }

  private safeMessages(): ChatMessage[] {
    return this.messages ? this.messages : [];
  }

  private pressed(key: string): boolean {
    return this.pressedKey === key;
  }

  private touchKey(key: string, event: TouchEvent): void {
    if (event.type === TouchType.Down) this.pressedKey = key;
    else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedKey = '';
  }

  private later(delay: number, action: () => void): void {
    this.timers.push(setTimeout(action, delay));
  }

  private wait(delay: number): Promise<void> {
    return new Promise<void>(resolve => {
      this.timers.push(setTimeout(() => resolve(), delay));
    });
  }

  private startMotionLoop(): void {
    const runId = ++this.motionRunId;
    this.motionTick = 0;
    this.advanceMotion(runId);
  }

  private advanceMotion(runId: number): void {
    if (runId !== this.motionRunId || (!this.booting && !this.pageSwitching && !this.themeSwitching)) return;
    this.motionTick = (this.motionTick + 1) % 120;
    this.later(120, () => this.advanceMotion(runId));
  }

  private startThinkingAnimation(): void {
    const runId = ++this.thinkingRunId;
    this.thinkingTick = 0;
    this.thinkingProgress = 4;
    this.thinkingFinishing = false;
    this.isThinking = true;
    this.advanceThinking(runId);
  }

  private advanceThinking(runId: number): void {
    if (runId !== this.thinkingRunId || !this.isThinking || this.thinkingFinishing) return;
    this.thinkingTick += 1;
    this.thinkingProgress = Math.min(92, 4 + this.thinkingTick * 4);
    this.later(140, () => this.advanceThinking(runId));
  }

  private thinkingLabel(): string {
    if (this.thinkingFinishing) return '回答准备完成';
    if (this.thinkingProgress < 30) return '正在理解问题';
    if (this.thinkingProgress < 58) return '正在检索家庭信息';
    if (this.thinkingProgress < 82) return '正在组织回答';
    return '正在校验结果';
  }

  private thinkingStep(): number {
    if (this.thinkingFinishing) return 4;
    if (this.thinkingProgress < 30) return 0;
    if (this.thinkingProgress < 58) return 1;
    if (this.thinkingProgress < 82) return 2;
    return 3;
  }

  private async completeThinkingAnimation(startedAt: number): Promise<void> {
    const remaining = Math.max(0, 3360 - (Date.now() - startedAt));
    if (remaining > 0) await this.wait(remaining);
    this.thinkingFinishing = true;
    this.thinkingProgress = 100;
    await this.wait(260);
    this.isThinking = false;
    this.thinkingRunId++;
  }

  private startBootSequence(): void {
    this.later(180, () => { this.bootStage = 1; this.bootProgress = 12; });
    this.later(700, () => { this.bootStage = 2; this.bootProgress = 32; });
    this.later(1250, () => { this.bootStage = 3; this.bootProgress = 58; });
    this.later(1800, () => { this.bootStage = 4; this.bootProgress = 82; });
    this.later(2350, () => { this.bootProgress = 100; });
    this.later(3050, () => { this.bootVisible = false; });
    this.revealAssistant(3060);
    this.later(3380, () => { this.booting = false; });
  }

  private revealAssistant(delay: number): void {
    this.assistantReveal = 0;
    this.later(delay, () => { this.assistantReveal = 1; });
    this.later(delay + 140, () => { this.assistantReveal = 2; });
    this.later(delay + 280, () => { this.assistantReveal = 3; });
  }

  private toggleTheme(): void {
    if (this.themeSwitching || this.pageSwitching) return;
    this.sourceDark = this.isDark;
    this.targetDark = !this.isDark;
    this.themeGradientAngle = this.targetDark ? 34 : 62;
    this.themeSweep = this.targetDark ? 580 : -580;
    this.themeSwitching = true;
    this.startMotionLoop();
    this.themeClosing = false;
    this.themeStage = 0;
    this.themeProgress = 4;
    this.later(32, () => {
      this.themeGradientAngle = this.targetDark ? 62 : 34;
      this.themeSweep = this.targetDark ? -580 : 580;
    });
    this.later(180, () => { this.themeStage = 1; this.themeProgress = 16; });
    this.later(440, () => { this.themeStage = 2; this.themeProgress = 36; });
    this.later(700, () => { this.isDark = this.targetDark; this.themeProgress = 58; });
    this.later(980, () => { this.themeStage = 3; this.themeProgress = 76; });
    this.later(1260, () => { this.themeProgress = 91; });
    this.later(1450, () => { this.themeStage = 4; this.themeProgress = 100; });
    this.later(1700, () => { this.themeClosing = true; });
    this.later(TacticalMotion.THEME_ROUTE, () => { this.themeSwitching = false; this.themeClosing = false; });
  }

  private switchPage(index: number): void {
    if (index === this.activePage || this.pageSwitching || this.themeSwitching) return;
    this.pageDirection = index > this.activePage ? 1 : -1;
    this.targetPage = index;
    this.pageSwitching = true;
    this.startMotionLoop();
    this.switchClosing = false;
    this.switchStage = 0;
    this.switchProgress = 3;
    if (index === 0) this.revealAssistant(1760);
    this.later(200, () => { this.switchStage = 1; this.switchProgress = 14; });
    this.later(520, () => { this.switchStage = 2; this.switchProgress = 31; });
    this.later(830, () => { this.contentVisible = false; this.switchProgress = 49; });
    this.later(950, () => { this.activePage = index; this.switchProgress = 61; });
    this.later(1220, () => { this.switchStage = 3; this.contentVisible = true; this.switchProgress = 76; });
    this.later(1510, () => { this.switchProgress = 91; });
    this.later(1700, () => { this.switchStage = 4; this.switchProgress = 100; });
    this.later(1960, () => { this.switchClosing = true; });
    this.later(TacticalMotion.ROUTE, () => { this.pageSwitching = false; this.switchClosing = false; });
  }

  private scrollToBottom(): void {
    setTimeout(() => { this.chatScroller.scrollEdge(Edge.Bottom); }, 60);
  }

  async send(): Promise<void> {
    const text = this.inputText.trim();
    if (!text) return;
    await this.submitMessage(text, '');
  }

  private async submitMessage(text: string, context: string): Promise<void> {
    if (!text.trim() || this.isResponding) return;
    const userMessage: ChatMessage = {
      id: `msg_${this.msgId++}`,
      role: ChatRole.USER,
      content: text.trim(),
      timestamp: Date.now(),
      context: context
    };
    this.messages = this.safeMessages().concat([userMessage]);
    this.inputText = '';
    this.scrollToBottom();

    const assistantId = `msg_${this.msgId++}`;
    const thinkingStartedAt = Date.now();
    let replyContent: string = '';
    let replyTimestamp: number = Date.now();
    let replyChartData: ChartData | undefined = undefined;
    let requestFailed: boolean = false;
    this.isResponding = true;
    this.startThinkingAnimation();
    this.messages = this.safeMessages().concat([{
      id: assistantId,
      role: ChatRole.ASSISTANT,
      content: '',
      timestamp: Date.now(),
      isStreaming: true
    }]);
    this.scrollToBottom();

    try {
      const finalMessage = await ChatApi.sendComplete(this.safeMessages().slice(0, -1));
      replyContent = finalMessage.content;
      replyTimestamp = finalMessage.timestamp;
      replyChartData = finalMessage.chartData;
    } catch (e) {
      const error = e as Error;
      requestFailed = true;
      replyContent = error.message || '智能服务暂时无法连接';
      replyTimestamp = Date.now();
    } finally {
      await this.completeThinkingAnimation(thinkingStartedAt);
      if (!replyContent) replyContent = '暂未收到有效回复';
      const completedId = `msg_${this.msgId++}`;
      this.revealingMessageId = completedId;
      this.replyVisible = false;
      this.messages = this.safeMessages().map((message: ChatMessage): ChatMessage =>
        message.id === assistantId ? {
          id: completedId,
          role: ChatRole.ASSISTANT,
          content: replyContent,
          timestamp: replyTimestamp,
          isStreaming: false,
          chartData: replyChartData
        } : message
      );
      await this.wait(24);
      this.replyVisible = true;
      if (!requestFailed) ChatApi.speak(replyContent);
      this.isResponding = false;
      this.scrollToBottom();
    }
  }

  private async analyzeChart(title: string, context: string): Promise<void> {
    if (this.isResponding || !context.trim()) return;
    this.activePage = 0;
    this.contentVisible = true;
    this.pageSwitching = false;
    this.inputText = '';
    await this.submitMessage(`请分析“${title}”图表，概括趋势、异常和建议。`, context);
  }

  async startVoice(): Promise<void> {
    if (this.isListening || this.isResponding) return;
    this.isListening = true;
    try {
      const text = await ChatApi.voiceToText('');
      this.inputText = text.trim();
      if (this.inputText) await this.send();
    } finally {
      this.isListening = false;
    }
  }

  @Builder
  backdrop() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(this.page())
      Column().width(3).height('100%').backgroundColor(this.accent()).opacity(0.72).position({ x: 0, y: 0 })
    }
    .width('100%')
    .height('100%')
    .animation({ duration: TacticalMotion.SWITCH, curve: Curve.EaseOut })
  }

  @Builder
  artTitle(title: string) {
    Stack({ alignContent: Alignment.Center }) {
      Text(title)
        .fontSize(28)
        .fontFamily('HarmonyOS Sans SC')
        .fontWeight(FontWeight.Bolder)
        .fontColor(TacticalTheme.gridStrong(this.isDark))
        .translate({ x: 2, y: 2 })
      Text(title)
        .fontSize(28)
        .fontFamily('HarmonyOS Sans SC')
        .fontWeight(FontWeight.Bolder)
        .fontColor(this.text())
      Column().width(34).height(2).backgroundColor(this.accent()).position({ x: 0, y: 39 })
      Column().width(8).height(8).border({ width: 1, color: this.accent() }).position({ x: 42, y: 35 })
        .rotate({ angle: 45 })
    }
    .constraintSize({ minWidth: 110 })
    .height(44)
    .accessibilityText(title)
  }

  @Builder
  loadingCore(progress: number, title: string, subtitle: string, icon: Resource) {
    Column({ space: 18 }) {
      Stack() {
        Progress({ value: progress, total: 100, type: ProgressType.Ring })
          .width(158).height(158).color(this.accent()).style({ strokeWidth: 2 })
          .opacity(progress < 10 ? 0.25 : 0.82)

        Column().width(164).height(164)
          .border({ width: 1, color: TacticalTheme.grid(this.isDark) })
          .opacity(progress < 20 ? 0 : 0.48)
          .scale({ x: progress < 20 ? 0.72 : 1, y: progress < 20 ? 0.72 : 1 })
          .rotate({ angle: this.motionTick * 2.4 })
          .animation({ duration: 120, curve: Curve.Linear })

        Column().width(144).height(144)
          .border({ width: 1, color: TacticalTheme.borderStrong(this.isDark) })
          .scale({ x: progress < 14 ? 0.84 : 1, y: progress < 14 ? 0.84 : 1 })
          .opacity(progress < 8 ? 0.3 : 1)
          .rotate({ angle: 45 - this.motionTick * 3.1 })
          .animation({ duration: 120, curve: Curve.Linear })

        Column().width(104).height(104)
          .border({ width: 1, color: this.accent() })
          .scale({ x: progress < 40 ? 0.72 : 1, y: progress < 40 ? 0.72 : 1 })
          .opacity(progress < 24 ? 0.25 : 1)
          .rotate({ angle: this.motionTick * 4.2 })
          .animation({ duration: 120, curve: Curve.Linear })

        Column().width(172).height(48)
          .border({ width: { top: 1, bottom: 1 }, color: TacticalTheme.gridStrong(this.isDark) })
          .rotate({ angle: this.motionTick * 1.35 })
          .opacity(0.62).animation({ duration: 120, curve: Curve.Linear })
        Column().width(48).height(172)
          .border({ width: { left: 1, right: 1 }, color: TacticalTheme.gridStrong(this.isDark) })
          .rotate({ angle: -this.motionTick * 1.7 })
          .opacity(0.48).animation({ duration: 120, curve: Curve.Linear })

        Column().width(1).height(144).backgroundColor(TacticalTheme.gridStrong(this.isDark)).opacity(0.72)
        Column().width(144).height(1).backgroundColor(TacticalTheme.gridStrong(this.isDark)).opacity(0.72)
        Column().width(4).height(24).backgroundColor(this.accent()).position({ x: 140, y: 120 })
          .translate({ y: progress < 58 ? 18 : 0 }).animation({ duration: 380, curve: Curve.EaseOut })
        Column().width(9).height(9).backgroundColor(this.text()).position({ x: 4, y: 132 })
          .opacity(progress < 46 ? 0 : 1).animation({ duration: 300, curve: Curve.EaseOut })
        Column().width(9).height(9).backgroundColor(this.accent()).position({ x: 132, y: 4 })
          .opacity(progress < 72 ? 0 : 1).animation({ duration: 300, curve: Curve.EaseOut })

        Stack() {
          Column().width(56).height(56).backgroundColor(this.accent())
          SymbolGlyph(icon).fontSize(26).fontColor([TacticalTheme.inverse(this.isDark)])
        }.width(56).height(56)
          .scale({ x: progress < 68 ? 0.82 : 1, y: progress < 68 ? 0.82 : 1 })
          .animation({ duration: 360, curve: Curve.EaseOut })
      }
      .width(172).height(172)

      Row({ space: 7 }) {
        ForEach([0, 1, 2, 3], (index: number) => {
          Column().width(index === Math.min(3, Math.floor(progress / 25)) ? 28 : 12).height(4)
            .backgroundColor(index === Math.min(3, Math.floor(progress / 25)) ? this.accent() : TacticalTheme.gridStrong(this.isDark))
            .animation({ duration: 260, curve: Curve.EaseOut })
        }, (index: number) => `${index}`)
      }.height(6).alignItems(VerticalAlign.Center)

      Column({ space: 4 }) {
        this.artTitle(title)
        Text(subtitle).fontSize(11).fontColor(this.secondary())
      }
      .alignItems(HorizontalAlign.Center)
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  themeCore() {
    Column({ space: 20 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 170, height: 170 })
          .fill(Color.Transparent)
          .stroke(TacticalTheme.gridStrong(this.targetDark))
          .strokeWidth(1)
          .opacity(0.52)
          .rotate({ angle: this.motionTick * 2.2 })
          .animation({ duration: 120, curve: Curve.Linear })

        Column().width(138).height(138)
          .border({ width: 1, color: TacticalTheme.borderStrong(this.targetDark) })
          .rotate({ angle: 45 - this.motionTick * 2.8 })
          .opacity(0.7)
          .animation({ duration: 120, curve: Curve.Linear })

        Circle({ width: 104, height: 104 })
          .fill(TacticalTheme.panelRaised(this.targetDark))
          .stroke(TacticalTheme.accent(this.targetDark))
          .strokeWidth(1)

        SymbolGlyph(this.targetDark ? $r('sys.symbol.moon_fill') : $r('sys.symbol.sun_max'))
          .fontSize(44)
          .fontColor([TacticalTheme.accent(this.targetDark)])
          .opacity(this.themeProgress < 34 ? 0.18 : 1)
          .scale({ x: this.themeProgress < 34 ? 0.72 : 1, y: this.themeProgress < 34 ? 0.72 : 1 })
          .rotate({ angle: this.targetDark ? this.themeProgress * 0.8 - 70 : 70 - this.themeProgress * 0.7 })
          .animation({ duration: 420, curve: Curve.EaseOut })

        Circle({ width: 7, height: 7 }).fill(TacticalTheme.accent(this.targetDark))
          .translate({ x: -62, y: this.themeProgress < 50 ? 22 : -28 })
          .animation({ duration: 520, curve: Curve.EaseInOut })
        Circle({ width: 4, height: 4 }).fill(TacticalTheme.text(this.targetDark))
          .translate({ x: 58, y: this.themeProgress < 68 ? -18 : 32 })
          .animation({ duration: 520, curve: Curve.EaseInOut })
      }.width(176).height(176)

      Column({ space: 5 }) {
        Text(this.targetDark ? '静夜' : '明昼')
          .fontSize(28).fontFamily('HarmonyOS Sans SC').fontWeight(FontWeight.Bolder)
          .fontColor(TacticalTheme.text(this.targetDark))
        Text(this.targetDark ? '夜色归于安静' : '晨光进入居所')
          .fontSize(11).fontColor(TacticalTheme.textSecondary(this.targetDark))
      }.alignItems(HorizontalAlign.Center)
    }.alignItems(HorizontalAlign.Center)
  }

  @Builder
  bootScreen() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(this.page())

      Row() {
        ForEach([0, 1, 2], (_: number, index: number) => {
          Column().layoutWeight(1).height('100%')
            .border({ width: { right: index < 2 ? 1 : 0 }, color: TacticalTheme.grid(this.isDark) })
        }, (_: number, index: number) => `${index}`)
      }.width('100%').height('100%').opacity(0.18)

      Row() {
        Column({ space: 2 }) {
          Text(`${this.bootProgress}%`).fontSize(34).fontWeight(FontWeight.Bold).fontColor(this.accent())
          Text('正在载入').fontSize(10).fontColor(this.muted())
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Column({ space: 2 }) {
          Text('明日家居').fontSize(14).fontFamily('HarmonyOS Sans SC')
            .fontWeight(FontWeight.Bold).fontColor(this.text())
          Text(`第 ${this.bootStage + 1} 阶段`).fontSize(10).fontColor(this.muted())
        }.alignItems(HorizontalAlign.End)
      }
      .width('100%').padding({ left: 26, right: 22, top: 24 }).alignItems(VerticalAlign.Top)

      Column({ space: 22 }) {
        this.loadingCore(this.bootProgress, '明日家居', '正在准备家庭控制界面', $r('sys.symbol.house_fill'))
        Text(this.bootLabel()).fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.secondary())
        Row({ space: 9 }) {
          Column().layoutWeight(1).height(1).backgroundColor(TacticalTheme.gridStrong(this.isDark))
          Text('万物互联，居有其序').fontSize(10).fontColor(this.muted())
          Column().layoutWeight(1).height(1).backgroundColor(TacticalTheme.gridStrong(this.isDark))
        }.width('72%').alignItems(VerticalAlign.Center)
      }
      .width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)

      Column({ space: 10 }) {
        Row() {
          Text(this.bootLabel()).fontSize(10).fontColor(this.muted())
          Blank()
          Text('本地与家庭数据').fontSize(10).fontWeight(FontWeight.Bold).fontColor(this.accent())
        }.width('100%')
        Progress({ value: this.bootProgress, total: 100, type: ProgressType.Linear })
          .width('100%').height(6).color(this.accent()).backgroundColor(TacticalTheme.panelMuted(this.isDark))
          .style({ strokeWidth: 6 }).animation({ duration: TacticalMotion.BOOT_STEP, curve: Curve.EaseOut })
        Row({ space: 4 }) {
          ForEach([0, 1, 2, 3, 4, 5, 6, 7], (index: number) => {
            Column().layoutWeight(1).height(index <= this.bootStage + 2 ? 4 : 2)
              .backgroundColor(index <= this.bootStage + 2 ? this.accent() : TacticalTheme.gridStrong(this.isDark))
          }, (index: number) => `${index}`)
        }.width('100%').height(6).alignItems(VerticalAlign.Center)
      }
      .width('100%').padding({ left: 26, right: 22, bottom: 32 }).position({ x: 0, y: '78%' })

      Column().width(3).height('100%').backgroundColor(this.accent()).position({ x: 0, y: 0 })
    }
    .width('100%')
    .height('100%')
    .opacity(this.bootVisible ? 1 : 0)
    .translate({ x: this.bootVisible ? 0 : -32 })
    .animation({ duration: TacticalMotion.PAGE, curve: Curve.EaseIn })
  }

  @Builder
  transitionCurtains() {
    Stack() {
      if (this.pageSwitching || this.themeSwitching) {
        Stack() {
          if (this.themeSwitching) {
            Column().width('100%').height('100%')
              .linearGradient({
                angle: this.themeGradientAngle,
                colors: [[TacticalTheme.page(this.targetDark), 0],
                  [TacticalTheme.structural(this.targetDark), 0.24],
                  [TacticalTheme.accentSoft(this.targetDark), 0.48],
                  [TacticalTheme.structural(this.targetDark), 0.74],
                  [TacticalTheme.page(this.targetDark), 1]]
              })
              .animation({ duration: 1480, curve: Curve.EaseInOut })

            Column().width('100%').height('100%')
              .backgroundColor(TacticalTheme.page(this.sourceDark))
              .opacity(this.themeProgress < 58 ? 1 : 0)
              .animation({ duration: 460, curve: Curve.EaseInOut })

            Column().width('155%').height('140%')
              .linearGradient({
                angle: 44,
                colors: [[TacticalTheme.page(this.targetDark), 0],
                  [TacticalTheme.structural(this.targetDark), 0.27],
                  [TacticalTheme.accentSoft(this.targetDark), 0.52],
                  [TacticalTheme.page(this.targetDark), 0.8],
                  [TacticalTheme.structural(this.targetDark), 1]]
              })
              .opacity(0.98)
              .rotate({ angle: -36 })
              .translate({ x: this.themeSweep, y: -this.themeSweep * 1.15 })
              .animation({ duration: 1480, curve: Curve.EaseInOut })
          } else {
            Column().width('100%').height('100%').backgroundColor(this.page())
          }

          if (this.pageSwitching) {
            Row() {
              ForEach([0, 1, 2], (_: number, index: number) => {
                Column().layoutWeight(1).height('100%')
                  .backgroundColor(index === 1 ? TacticalTheme.structural(this.isDark) : this.page())
                  .border({ width: { right: index < 2 ? 1 : 0 }, color: TacticalTheme.grid(this.isDark) })
                  .translate({ y: this.switchProgress < (index + 1) * 18 ? (index % 2 === 0 ? -32 : 32) : 0 })
                  .animation({ duration: 460, curve: Curve.EaseOut })
              }, (_: number, index: number) => `${index}`)
            }.width('100%').height('100%').opacity(0.34)
          }

          Row() {
            Column({ space: 1 }) {
              Text(`${this.pageSwitching ? this.switchProgress : this.themeProgress}%`)
                .fontSize(35).fontWeight(FontWeight.Bold).fontColor(this.accent())
              Text(this.themeSwitching ? '正在调整光影' : '正在切换页面').fontSize(10).fontColor(this.muted())
            }.alignItems(HorizontalAlign.Start)
            Blank()
            Text(this.themeSwitching ? (this.targetDark ? '切换至深色' : '切换至浅色') : this.targetLabel())
              .fontSize(14).fontFamily('HarmonyOS Sans SC')
              .fontWeight(FontWeight.Bold).fontColor(this.text())
          }
          .width('100%').padding({ left: 26, right: 22, top: 24 })

          Column({ space: 20 }) {
            if (this.themeSwitching) {
              this.themeCore()
            } else {
              this.loadingCore(this.switchProgress, this.targetLabel(), '正在整理页面内容',
                this.targetPage === 0 ? $r('sys.symbol.mic_fill') : $r('sys.symbol.clock_fill'))
              Text(this.switchLabel()).fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.secondary())
            }
          }
          .width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)

          Column({ space: 10 }) {
            Row() {
              Text(this.themeSwitching ? (this.isDark ? '当前为深色' : '当前为浅色') : activePageLabel(this.activePage))
                .fontSize(10).fontColor(this.muted())
              Blank()
              Text(this.themeSwitching ? (this.targetDark ? '目标为深色' : '目标为浅色') : this.targetLabel())
                .fontSize(10).fontWeight(FontWeight.Bold).fontColor(this.accent())
            }.width('100%')
            Progress({ value: this.pageSwitching ? this.switchProgress : this.themeProgress,
              total: 100, type: ProgressType.Linear })
              .width('100%').height(6).color(this.accent()).backgroundColor(TacticalTheme.panelMuted(this.isDark))
              .style({ strokeWidth: 6 }).animation({ duration: TacticalMotion.BOOT_STEP, curve: Curve.EaseOut })
            Row({ space: 6 }) {
              ForEach([0, 1, 2, 3, 4, 5], (index: number) => {
                Column().layoutWeight(1)
                  .height((this.pageSwitching ? this.switchProgress : this.themeProgress) >= (index + 1) * 16 ? 5 : 2)
                  .backgroundColor((this.pageSwitching ? this.switchProgress : this.themeProgress) >= (index + 1) * 16 ?
                    this.accent() : TacticalTheme.gridStrong(this.isDark))
              }, (index: number) => `${index}`)
            }.width('100%').height(7).alignItems(VerticalAlign.Center)
          }
          .width('100%').padding({ left: 26, right: 22, bottom: 32 }).position({ x: 0, y: '78%' })

          Column().width(3).height('100%').backgroundColor(this.accent()).position({ x: 0, y: 0 })
        }
        .width('100%').height('100%')
        .opacity(this.pageSwitching ? (this.switchClosing ? 0 : 1) : (this.themeClosing ? 0 : 1))
        .animation({ duration: TacticalMotion.PAGE, curve: Curve.EaseOut })
        .enabled(false)
      }
    }
    .width('100%')
    .height('100%')
    .enabled(false)
  }

  @Builder
  brandMark() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(184)
        .height(50)
        .backgroundColor('#FFFFFF')
        .border({ width: { bottom: 2 }, color: this.brandAccent() })

      Text('明')
        .fontSize(43)
        .fontFamily('HarmonyOS Sans SC')
        .fontWeight(FontWeight.Bold)
        .fontColor(this.brandGhost())
        .position({ x: 12, y: -6 })

      Column().width(4).height(36).backgroundColor(this.brandAccent()).position({ x: 0, y: 7 })
      Column().width(34).height(2).backgroundColor(this.brandAccent()).position({ x: 150, y: 0 })
      Column().width(16).height(1).backgroundColor(this.brandInk()).position({ x: 168, y: 6 })
      Column().width(8).height(8).border({ width: 1, color: this.brandAccent() }).position({ x: 170, y: 36 })
        .rotate({ angle: 45 })
      Column().width(1).height(24).backgroundColor(this.brandGhost()).position({ x: 142, y: 13 })

      Stack() {
        Row({ space: 0 }) {
          Text('明日')
            .fontSize(27)
            .fontFamily('HarmonyOS Sans SC')
            .fontWeight(FontWeight.Bolder)
            .fontColor(this.brandGhost())
          Text('家居')
            .fontSize(27)
            .fontFamily('HarmonyOS Sans SC')
            .fontWeight(FontWeight.Bolder)
            .fontColor(this.brandGhost())
        }.translate({ x: 2, y: 2 })
        Row({ space: 0 }) {
          Text('明日')
            .fontSize(27)
            .fontFamily('HarmonyOS Sans SC')
            .fontWeight(FontWeight.Bolder)
            .fontColor(this.brandInk())
          Text('家居')
            .fontSize(27)
            .fontFamily('HarmonyOS Sans SC')
            .fontWeight(FontWeight.Bolder)
            .fontColor(this.brandAccent())
        }
      }
      .width(136)
      .height(38)
    }
    .width(184)
    .height(50)
    .accessibilityText('明日家居')
  }

  @Builder
  topBar() {
    Row({ space: 10 }) {
      this.brandMark()

      Blank()

      Stack() {
        Column().width(48).height(48)
          .backgroundColor(this.pressed('theme') ? TacticalTheme.accentSoft(this.isDark) : this.panel())
          .border({ width: 1, color: this.accent() })
        SymbolGlyph(this.isDark ? $r('sys.symbol.sun_max') : $r('sys.symbol.moon_fill'))
          .fontSize(21)
          .fontColor([this.accent()])
      }
      .width(48)
      .height(48)
      .opacity(this.pressed('theme') ? 0.72 : 1)
      .scale({ x: this.pressed('theme') ? 0.94 : 1, y: this.pressed('theme') ? 0.94 : 1 })
      .animation({ duration: TacticalMotion.PRESS, curve: Curve.EaseOut })
      .accessibilityText(this.isDark ? '切换到白天模式' : '切换到黑夜模式')
      .onTouch((event: TouchEvent) => this.touchKey('theme', event))
      .onClick(() => this.toggleTheme())
    }
    .width('100%')
    .height(68)
    .padding({ left: 18, right: 16, top: 9, bottom: 9 })
    .backgroundColor(this.panel())
    .border({ width: { bottom: 1 }, color: this.frameTone() })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  thinkingIndicator() {
    Row({ space: 12 }) {
      Stack() {
        Progress({ value: this.thinkingProgress, total: 100, type: ProgressType.Ring })
          .width(44).height(44).color(this.accent()).style({ strokeWidth: 2 })
          .animation({ duration: this.thinkingFinishing ? 220 : 180, curve: Curve.EaseOut })
        Column().width(34).height(34).border({ width: 1, color: TacticalTheme.borderStrong(this.isDark) })
          .rotate({ angle: this.thinkingFinishing ? 45 : this.thinkingTick * 18 })
          .scale({ x: this.thinkingFinishing ? 0.82 : 1, y: this.thinkingFinishing ? 0.82 : 1 })
          .opacity(this.thinkingFinishing ? 0.42 : 0.9)
          .animation({ duration: this.thinkingFinishing ? 240 : 140,
            curve: this.thinkingFinishing ? Curve.EaseOut : Curve.Linear })
        Column().width(22).height(22).border({ width: 1, color: this.accent() })
          .backgroundColor(TacticalTheme.ghost(this.isDark))
          .rotate({ angle: this.thinkingFinishing ? 45 : 45 - this.thinkingTick * 27 })
          .scale({ x: this.thinkingFinishing ? 0.68 : 1, y: this.thinkingFinishing ? 0.68 : 1 })
          .animation({ duration: this.thinkingFinishing ? 240 : 140,
            curve: this.thinkingFinishing ? Curve.EaseOut : Curve.Linear })
        if (this.thinkingFinishing) {
          SymbolGlyph($r('sys.symbol.checkmark'))
            .fontSize(16)
            .fontColor([this.accent()])
            .scale({ x: this.thinkingFinishing ? 1 : 0.72, y: this.thinkingFinishing ? 1 : 0.72 })
            .animation({ duration: 200, curve: Curve.EaseOut })
        } else {
          Column().width(6).height(6).backgroundColor(this.accent())
            .scale({ x: this.thinkingTick % 2 === 0 ? 0.66 : 1, y: this.thinkingTick % 2 === 0 ? 0.66 : 1 })
            .animation({ duration: 140, curve: Curve.EaseInOut })
        }
      }.width(46).height(46)

      Column({ space: 7 }) {
        Row() {
          Text(this.thinkingLabel())
            .fontSize(16)
            .fontFamily('HarmonyOS Sans SC')
            .fontWeight(FontWeight.Bold)
            .fontColor(this.text())
          Blank()
          Text(`${Math.round(this.thinkingProgress)}%`).fontSize(10).fontWeight(FontWeight.Bold).fontColor(this.accent())
        }.width('100%').alignItems(VerticalAlign.Center)
        Row({ space: 5 }) {
          ForEach([0, 1, 2, 3], (index: number) => {
            Column().width(25).height(3)
              .backgroundColor(index <= this.thinkingStep() ? this.accent() : TacticalTheme.gridStrong(this.isDark))
              .opacity(index === this.thinkingStep() && !this.thinkingFinishing ? 0.62 : 1)
              .scale({ x: index === this.thinkingStep() && !this.thinkingFinishing ? 0.88 : 1, y: 1 })
              .animation({ duration: 180, curve: Curve.EaseOut })
          }, (index: number) => `${index}`)
        }.height(4).alignItems(VerticalAlign.Center)
      }.width(115).alignItems(HorizontalAlign.Start)
    }
    .padding({ left: 12, right: 16, top: 10, bottom: 10 })
    .backgroundColor(this.raised())
    .border({ width: { left: 2 }, color: this.accent() })
    .constraintSize({ maxWidth: '86%' })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  assistantMessage(message: ChatMessage) {
    Column({ space: 8 }) {
      Row({ space: 7 }) {
        Text('明日')
          .fontSize(12)
          .fontFamily('HarmonyOS Sans SC')
          .fontWeight(FontWeight.Bold)
          .fontColor(this.accent())
        Column().width(30).height(2).backgroundColor(this.accent())
        Column().width(5).height(5).border({ width: 1, color: this.accent() }).rotate({ angle: 45 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(message.content)
        .fontSize(15)
        .fontFamily('HarmonyOS Sans SC')
        .fontWeight(FontWeight.Regular)
        .lineHeight(24)
        .fontColor(this.text())
        .width('100%')

      if (message.chartData && message.chartData.charts && message.chartData.charts.length > 0) {
        ChatChartPanel({ chartData: message.chartData, isDark: this.isDark })
      }

      Row() {
        Column().layoutWeight(1).height(1).backgroundColor(TacticalTheme.grid(this.isDark))
        Column().width(7).height(7).border({ width: 1, color: this.accent() }).rotate({ angle: 45 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .padding({ left: 14, right: 12, top: 10, bottom: 8 })
    .width('82%')
    .backgroundColor(this.raised())
    .border({ width: { left: 3, bottom: 1 }, color: this.accent() })
    .opacity(message.id === this.revealingMessageId && !this.replyVisible ? 0 : 1)
    .translate({ y: message.id === this.revealingMessageId && !this.replyVisible ? 8 : 0 })
    .animation({ duration: 280, curve: Curve.EaseOut })
  }

  @Builder
  chatBubble(message: ChatMessage) {
    Row() {
      if (message.role === ChatRole.USER) {
        Blank()
      }
      if (message.role === ChatRole.ASSISTANT && message.isStreaming) {
        this.thinkingIndicator()
      } else if (message.role === ChatRole.ASSISTANT) {
        this.assistantMessage(message)
      } else {
        Text(message.content)
          .fontSize(15)
          .lineHeight(23)
          .fontColor(TacticalTheme.inverse(this.isDark))
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor(this.accent())
          .constraintSize({ maxWidth: '86%' })
      }
      if (message.role === ChatRole.ASSISTANT) {
        Blank()
      }
    }
    .width('100%')
    .padding({ left: 2, right: 2 })
  }

  @Builder
  iconButton(key: string, label: string, icon: Resource, selected: boolean, enabled: boolean, action: () => void) {
    Stack() {
      Column()
        .width(48)
        .height(48)
        .backgroundColor(selected ? this.accent() : this.panel())
        .border({ width: 1, color: selected ? this.accent() : this.frameTone() })
      SymbolGlyph(icon)
        .fontSize(20)
        .fontColor([selected ? TacticalTheme.inverse(this.isDark) : this.accent()])
    }
    .width(48)
    .height(48)
    .opacity(!enabled ? 0.42 : this.pressed(key) ? 0.72 : 1)
    .scale({ x: this.pressed(key) ? 0.94 : 1, y: this.pressed(key) ? 0.94 : 1 })
    .animation({ duration: TacticalMotion.PRESS, curve: Curve.EaseOut })
    .accessibilityText(label)
    .enabled(enabled)
    .onTouch((event: TouchEvent) => this.touchKey(key, event))
    .onClick(action)
  }

  @Builder
  sendButton() {
    Stack() {
      Column().width(48).height(48)
        .backgroundColor(this.inputText.trim().length > 0 && !this.isResponding ? this.accent() : this.panel())
        .border({ width: 1, color: this.inputText.trim().length > 0 && !this.isResponding ? this.accent() : this.frameTone() })
      SymbolGlyph($r('sys.symbol.paperplane_fill')).fontSize(20)
        .fontColor([this.inputText.trim().length > 0 && !this.isResponding ? TacticalTheme.inverse(this.isDark) : this.muted()])
    }
    .width(48).height(48)
    .opacity(this.pressed('send') ? 0.68 : 1)
    .scale({ x: this.pressed('send') ? 0.94 : 1, y: this.pressed('send') ? 0.94 : 1 })
    .animation({ duration: TacticalMotion.PRESS, curve: Curve.EaseOut })
    .accessibilityText('发送消息')
    .onTouch((event: TouchEvent) => this.touchKey('send', event))
    .onClick(() => this.send())
  }

  @Builder
  assistantPage() {
    Column({ space: 10 }) {
      Row({ space: 7 }) {
        Circle({ width: 7, height: 7 }).fill(this.isResponding ? this.accent() : TacticalTheme.gridStrong(this.isDark))
        Text(this.isResponding ? '正在书写' : '明日对话录')
          .fontSize(13)
          .fontFamily('HarmonyOS Sans SC')
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isResponding ? this.accent() : this.text())
        Column().width(28).height(1).backgroundColor(this.isResponding ? this.accent() : this.frameTone())
      }.width('100%').height(26)
        .border({ width: { bottom: 1 }, color: TacticalTheme.grid(this.isDark) })
        .opacity(this.assistantReveal >= 1 ? 1 : 0)
        .translate({ y: this.assistantReveal >= 1 ? 0 : 8 })
        .animation({ duration: 320, curve: Curve.EaseOut })

      Scroll(this.chatScroller) {
        Column({ space: 10 }) {
          ForEach(this.safeMessages(), (message: ChatMessage) => { this.chatBubble(message) }, (message: ChatMessage) => message.id)
        }
        .width('100%')
        .padding({ top: 4, bottom: 8 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .opacity(this.assistantReveal >= 2 ? 1 : 0)
      .translate({ y: this.assistantReveal >= 2 ? 0 : 12 })
      .animation({ duration: 360, curve: Curve.EaseOut })

      Row({ space: 8 }) {
        TextInput({ text: this.inputText, placeholder: this.isListening ? '正在聆听...' : '输入消息' })
          .layoutWeight(1)
          .height(48)
          .fontSize(15)
          .fontColor(this.text())
          .placeholderColor(this.muted())
          .backgroundColor(this.input())
          .border({ width: 1, color: this.frameTone() })
          .padding({ left: 14, right: 14 })
          .enabled(!this.isResponding)
          .onChange((value: string) => { this.inputText = value; })
          .onSubmit(() => this.send())
        this.iconButton('voice', this.isListening ? '停止语音输入' : '开始语音输入',
          this.isListening ? $r('sys.symbol.mic_badge_recordingtape') : $r('sys.symbol.mic_fill'),
          this.isListening, !this.isResponding, () => this.startVoice())
        this.sendButton()
      }
      .width('100%')
      .padding(8)
      .backgroundColor(this.raised())
      .border({ width: 1, color: this.frameTone() })
      .opacity(this.assistantReveal >= 3 ? 1 : 0)
      .translate({ y: this.assistantReveal >= 3 ? 0 : 10 })
      .animation({ duration: 360, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
  }

  @Builder
  navItem(index: number, label: string, icon: Resource) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Row({ space: 9 }) {
        SymbolGlyph(icon)
          .fontSize(19)
          .fontColor([this.activePage === index ? TacticalTheme.inverse(this.isDark) : this.accent()])
        Text(label).fontSize(13).fontWeight(FontWeight.Bold)
          .fontFamily('HarmonyOS Sans SC')
          .fontColor(this.activePage === index ? TacticalTheme.inverse(this.isDark) : this.secondary())
      }
      .padding({ left: 16, bottom: 12 })

      Column()
        .width(this.activePage === index ? '100%' : 24)
        .height(3)
        .backgroundColor(this.activePage === index ? TacticalTheme.inverse(this.isDark) : this.accent())
        .animation({ duration: TacticalMotion.SWITCH, curve: Curve.EaseOut })
    }
    .layoutWeight(1)
    .height(56)
    .backgroundColor(this.activePage === index ? this.accent() : this.panel())
    .border({ width: 1, color: this.activePage === index ? this.accent() : this.frameTone() })
    .opacity(this.pressed(`nav_${index}`) ? 0.72 : 1)
    .scale({ x: this.pressed(`nav_${index}`) ? 0.97 : 1, y: this.pressed(`nav_${index}`) ? 0.97 : 1 })
    .animation({ duration: TacticalMotion.PRESS, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => this.touchKey(`nav_${index}`, event))
    .onClick(() => this.switchPage(index))
  }

  @Builder
  bottomNav() {
    Row({ space: 8 }) {
      this.navItem(0, '助手', $r('sys.symbol.mic_fill'))
      this.navItem(1, '数据管理', $r('sys.symbol.clock_fill'))
    }
    .width('100%')
    .height(80)
    .padding({ left: 12, right: 12, top: 8, bottom: 12 })
    .backgroundColor(this.raised())
    .border({ width: { top: 1 }, color: this.frameTone() })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      this.backdrop()
      Column() {
        this.topBar()
        Column() {
          if (this.activePage === 0) {
            this.assistantPage()
          } else {
            Scroll() {
              HistoryPage({
                isDark: this.isDark,
                onAnalyzeChart: (title: string, context: string): void => { this.analyzeChart(title, context); }
              })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
          }
        }
        .layoutWeight(1)
        .width('100%')
        .opacity(this.contentVisible ? 1 : 0)
        .translate({ x: this.contentVisible ? 0 : this.pageDirection * 28 })
        .animation({ duration: TacticalMotion.PAGE, curve: Curve.EaseOut })
        this.bottomNav()
      }
      .width('100%')
      .height('100%')

      this.transitionCurtains()

      if (this.booting) {
        this.bootScreen()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.page())
  }
}

function activePageLabel(index: number): string {
  return index === 0 ? '明日家居' : '数据管理';
}
