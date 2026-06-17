/**
 * 大模型对话 API · ChatFlow
 *
 * 接口契约:
 *   POST /api/chat/send  { messages, sessionId }
 *        → 流式返回 (SSE): data: { token }  ...  data: [DONE]
 *   POST /api/chat/voice → 语音输入 (上传音频) → { text }
 *   GET  /api/chat/voice/{id} → 语音输出 (TTS 音频流)
 *
 * 支持: 多轮上下文 / 流式输出 / 语音双工
 */
import { ChatMessage, ChatRole } from './types';
import { MockData } from '../mock/mockData';

let msgIdCounter = 100;

export class ChatApi {
  /**
   * 发送消息（流式回调）
   * TODO[后端对接]: 替换为 fetch + ReadableStream / EventSource SSE
   * @param messages 全部历史消息（含本次提问）
   * @param onToken  每收到一个 token 的回调
   * @param onDone   流结束回调，返回完整回复
   */
  static async sendStream(
    messages: ChatMessage[],
    onToken: (token: string) => void,
    onDone: (full: ChatMessage) => void
  ): Promise<void> {
    // TODO[后端对接]: POST /api/chat/send  (SSE stream)
    const reply = ChatApi.mockReply(messages[messages.length - 1]?.content || '');
    let i = 0;
    return new Promise(resolve => {
      const timer = setInterval(() => {
        if (i >= reply.length) {
          clearInterval(timer);
          onDone({
            id: 'msg_' + (msgIdCounter++),
            role: ChatRole.ASSISTANT,
            content: reply,
            timestamp: Date.now()
          });
          resolve();
          return;
        }
        // 每次输出 1-2 个字，模拟流式
        const step = reply[i] === ' ' ? 2 : 1;
        onToken(reply.slice(0, i + step));
        i += step;
      }, 55);
    });
  }

  /**
   * 语音输入（上传音频转文字）
   * TODO[后端对接]: POST /api/chat/voice (multipart 音频)
   */
  static async voiceToText(audioPath: string): Promise<string> {
    // TODO[后端对接]: 上传音频文件，返回识别文本
    return new Promise(resolve => setTimeout(() => resolve('把客厅空调调到 24 度'), 600));
  }

  /**
   * 文字转语音输出
   * TODO[后端对接]: GET /api/chat/voice/{id} → 音频流
   */
  static async textToVoice(text: string): Promise<string> {
    // TODO[后端对接]: 返回 TTS 音频地址
    return new Promise(resolve => setTimeout(() => resolve(''), 400));
  }

  /** 获取欢迎语 */
  static getWelcome(): string {
    return MockData.chatWelcome;
  }

  /** Mock 回复生成（关键词匹配，仅本地预览） */
  private static mockReply(input: string): string {
    const q = input.toLowerCase();
    if (q.includes('空调') || q.includes('温度')) return '好的，我已为你将客厅空调设定为 24°C 制冷模式，预计 8 分钟后达到目标温度。';
    if (q.includes('风扇')) return '客厅吊扇已开启 2 档风，如需调整请告诉我。';
    if (q.includes('门') || q.includes('开锁')) return '已向入户门禁发送开锁指令，请确认是你本人操作。门将在 8 秒后自动关闭。';
    if (q.includes('安全') || q.includes('监控')) return '目前全屋安防状态正常。客厅摄像头在线并正在录像，未检测到异常活动。';
    if (q.includes('灯')) return '已为你打开客厅主灯，亮度 80%。';
    if (q.includes('能耗') || q.includes('电')) return '今日用电 14.3 度，较昨日下降 6%。实时功率 1.86kW，处于正常区间。';
    if (q.includes('你好') || q.includes('hi') || q.includes('hello')) return '你好！有什么可以帮你的吗？可以试试问我控制家电或查看家里的情况。';
    return '收到你的消息。我可以帮你控制风扇、空调、门禁，查询传感器数据，或查看监控。请告诉我你想做什么。';
  }
}
