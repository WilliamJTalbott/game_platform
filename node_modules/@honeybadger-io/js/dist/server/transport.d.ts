import { Types } from '@honeybadger-io/core';
export declare class ServerTransport implements Types.Transport {
    private readonly headers;
    constructor(headers?: Record<string, string>);
    defaultHeaders(): Record<string, string>;
    send<T>(options: Types.TransportOptions, payload?: T): Promise<{
        statusCode: number;
        body: string;
    }>;
    private isNoticePayload;
    private appendMetadata;
}
//# sourceMappingURL=transport.d.ts.map