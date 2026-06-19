/**
 * 大模型对话 API · 对接设备端网关（DeepSeek）
 * 策略: HTTP POST /api/chat/send 获取真实回复，失败降级到本地关键词回复
 * 流式: 网关返回完整文本，前端模拟逐字打字效果
 */
import { ChatMessage, ChatRole } from './types';
import { MockData } from '../mock/mockData';
import { Http } from './http';

let msgIdCounter = 100;

interface ChatSendRequest {
  messages: ChatMessage[];
}

interface ChatReplyResponse {
  reply: string;
  role: string;
}

export class ChatApi {
  /**
   * 发送消息（流式打字效果）
   * 先从网关获取完整回复，再逐字吐出模拟流式
   */
  static async sendStream(
    messages: ChatMessage[],
    onToken: (token: string) => void,
    onDone: (full: ChatMessage) => void
  ): Promise<void> {
    // 1. 调网关获取真实回复
    let reply: string = '';
    const body: ChatSendRequest = { messages };
    const respText = await Http.post('/api/chat/send', body);
    if (respText) {
      try {
        const resp = JSON.parse(respText) as ChatReplyResponse;
        if (resp.reply) reply = resp.reply;
      } catch (e) {
        // 降级
      }
    }
    if (!reply) {
      reply = ChatApi.mockReply(messages[messages.length - 1]?.content || '');
    }

    // 2. 逐字吐出（模拟流式打字）
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
        const step = reply[i] === ' ' ? 2 : 1;
        onToken(reply.slice(0, i + step));
        i += step;
      }, 40);
    });
  }

  /** 语音输入（占位） */
  static async voiceToText(audioPath: string): Promise<string> {
    return new Promise(resolve => setTimeout(() => resolve('把客厅空调调到 24 度'), 600));
  }

  /** 文字转语音（占位） */
  static async textToVoice(text: string): Promise<string> {
    return new Promise(resolve => setTimeout(() => resolve(''), 400));
  }

  /** 欢迎语 */
  static getWelcome(): string {
    return MockData.chatWelcome;
  }

  /** 本地降级回复（网关不可用时） */
  private static mockReply(input: string): string {
    const q = input.toLowerCase();
    if (q.includes('空调') || q.includes('温度')) return '好的，我已为你将客厅空调设定为 24°C 制冷模式。';
    if (q.includes('风扇')) return '客厅吊扇已开启 2 档风，如需调整请告诉我。';
    if (q.includes('门') || q.includes('开锁')) return '已向入户门禁发送开锁指令。';
    if (q.includes('你好') || q.includes('hi')) return '你好！有什么可以帮你的吗？';
    return '收到。我可以帮你控制风扇、空调、门禁，查询传感器数据。请告诉我你想做什么。';
  }
}
