import Client from '../../server';
export default class UnhandledRejectionMonitor {
    protected __isReporting: boolean;
    protected __client: typeof Client;
    protected __listener: (reason: unknown, _promise: Promise<unknown>) => void;
    constructor();
    setClient(client: typeof Client): void;
    makeListener(): (reason: unknown, _promise: Promise<unknown>) => void;
    maybeAddListener(): void;
    maybeRemoveListener(): void;
    /**
     * If there are no other unhandledRejection listeners,
     * we want to report the exception to Honeybadger and
     * mimic the default behavior of NodeJs,
     * which is to exit the process with code 1
     */
    hasOtherUnhandledRejectionListeners(): boolean;
}
//# sourceMappingURL=unhandled_rejection_monitor.d.ts.map