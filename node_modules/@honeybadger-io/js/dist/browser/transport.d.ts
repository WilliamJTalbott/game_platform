import { Types } from '@honeybadger-io/core';
export declare class BrowserTransport implements Types.Transport {
    private headers;
    constructor(headers?: Record<string, string>);
    defaultHeaders(): Record<string, string>;
    send<T>(options: Types.TransportOptions, payload?: T): Promise<{
        statusCode: number;
        body: string;
    }>;
}
//# sourceMappingURL=transport.d.ts.map