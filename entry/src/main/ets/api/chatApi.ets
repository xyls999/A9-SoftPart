/**
 * 大模型对话 API · 对接设备端网关（DeepSeek）
 * 策略: HTTP POST /api/chat/send 获取真实回复
 * 流式: 网关返回完整文本，前端模拟逐字打字效果
 */
import { ChatMessage, ChatRole } from './types';
import { Http } from './http';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;
const TAG = 'SmartHomeChat';

let msgIdCounter = 100;

interface ChatSendRequest {
  messages: ChatPayloadMessage[];
}

interface ChatPayloadMessage {
  role: string;
  content: string;
}

interface ChatReplyResponse {
  reply: string;
  role?: string;
  provider?: string;
}

interface TtsSpeakResponse {
  ok?: boolean;
  played?: boolean;
  backend?: string;
}

interface TtsSpeakRequest {
  text: string;
  speed: number;
}

interface AiModelConfig {
  model?: string;
}

interface AiConfigResponse {
  provider?: string;
  models?: Record<string, AiModelConfig>;
}

interface TtsConfigResponse {
  enabled?: boolean;
  backend?: string;
}

export interface ChatBackendStatus {
  provider: string;
  model: string;
  ttsBackend: string;
  ttsEnabled: boolean;
}

export class ChatApi {
  /**
   * 发送消息（流式打字效果）
   * 先从网关获取完整回复，再逐字吐出模拟流式
   * 关键修复: 无论 HTTP 成功或失败，onDone 必定被调用
   */
  static async sendStream(
    messages: ChatMessage[],
    onToken: (token: string) => void,
    onDone: (full: ChatMessage) => void
  ): Promise<void> {
    const body: ChatSendRequest = {
      messages: messages.map((m: ChatMessage): ChatPayloadMessage => ({
        role: m.role,
        content: m.content
      }))
    };
    hilog.info(DOMAIN, TAG, `sendStream start, msgs=${messages.length}`);

    const respText = await ChatApi.raceTimeout(Http.post('/api/chat/send', body), 25000);
    if (!respText) {
      throw new Error('小智助手暂时无法连接，请稍后再试');
    }

    let reply: string = '';
    try {
      const resp = JSON.parse(respText) as ChatReplyResponse;
      reply = resp.reply ? resp.reply.trim() : '';
      hilog.info(DOMAIN, TAG, `got reply: ${reply.substring(0, 40)}`);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, `JSON parse failed, raw: ${respText.substring(0, 80)}`);
      throw new Error('AI 后端返回格式异常');
    }

    if (!reply) {
      throw new Error('AI 后端没有返回 reply');
    }

    hilog.info(DOMAIN, TAG, `starting typewriter, reply len=${reply.length}`);
    let i = 0;
    return new Promise<void>(resolve => {
      const timer = setInterval(() => {
        if (i >= reply.length) {
          clearInterval(timer);
          onDone({
            id: 'msg_' + (msgIdCounter++),
            role: ChatRole.ASSISTANT,
            content: reply,
            timestamp: Date.now()
          });
          hilog.info(DOMAIN, TAG, `typewriter done`);
          resolve();
          return;
        }
        const step = reply[i] === ' ' ? 2 : 1;
        onToken(reply.slice(0, i + step));
        i += step;
      }, 35);
    });
  }

  /**
   * 超时竞速: 如果 promise 在 ms 内未完成，返回 null
   * 防止 Http.post 永久挂起导致聊天卡死
   */
  private static raceTimeout(promise: Promise<string | null>, ms: number): Promise<string | null> {
    return new Promise<string | null>(resolve => {
      let done = false;
      const timer = setTimeout(() => {
        if (!done) {
          done = true;
          hilog.warn(DOMAIN, TAG, `raceTimeout fired after ${ms}ms`);
          resolve(null);
        }
      }, ms);
      promise.then(result => {
        if (!done) {
          done = true;
          clearTimeout(timer);
          resolve(result);
        }
      }).catch(() => {
        if (!done) {
          done = true;
          clearTimeout(timer);
          resolve(null);
        }
      });
    });
  }

  /** 语音输入：没有真实 ASR 返回时不生成默认文字 */
  static async voiceToText(audioPath: string): Promise<string> {
    return '';
  }

  /** 调用后端 TTS 播报文本 */
  static async speak(text: string): Promise<boolean> {
    if (!text.trim()) return false;
    const body: TtsSpeakRequest = { text, speed: 5 };
    const respText = await Http.post('/api/tts/speak', body);
    if (respText) {
      try {
        const resp = JSON.parse(respText) as TtsSpeakResponse;
        return resp.ok === true || resp.played === true;
      } catch (e) {
      }
    }
    return false;
  }

  /** 兼容旧调用：文字转语音 */
  static async textToVoice(text: string): Promise<string> {
    await ChatApi.speak(text);
    return '';
  }

  /** 获取 AI/TTS 后端状态，用于原有顶部状态文案 */
  static async getBackendStatus(): Promise<ChatBackendStatus> {
    const status: ChatBackendStatus = {
      provider: '暂无',
      model: '暂无',
      ttsBackend: '暂无',
      ttsEnabled: false
    };

    const aiText = await Http.get('/api/ai/config');
    if (aiText) {
      try {
        const ai = JSON.parse(aiText) as AiConfigResponse;
        status.provider = ai.provider || status.provider;
        const modelConfig = ai.models ? ai.models[status.provider] : undefined;
        status.model = modelConfig?.model || status.model;
      } catch (e) {
      }
    }

    const ttsText = await Http.get('/api/tts/config');
    if (ttsText) {
      try {
        const tts = JSON.parse(ttsText) as TtsConfigResponse;
        status.ttsBackend = tts.backend || status.ttsBackend;
        status.ttsEnabled = tts.enabled !== false;
      } catch (e) {
      }
    }

    return status;
  }

  /** 欢迎语 */
  static getWelcome(): string {
    return '你好，我是智泽家居。你可以直接输入问题，我会让小智助手为你处理。';
  }
}
