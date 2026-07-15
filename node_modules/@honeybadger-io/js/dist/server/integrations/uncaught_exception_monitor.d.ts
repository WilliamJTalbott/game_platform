import Client from '../../server';
export default class UncaughtExceptionMonitor {
    protected __isReporting: boolean;
    protected __handlerAlreadyCalled: boolean;
    protected __client: typeof Client;
    protected __listener: (error: Error) => void;
    constructor();
    setClient(client: typeof Client): void;
    makeListener(): (uncaughtError: Error) => void;
    maybeAddListener(): void;
    maybeRemoveListener(): void;
    removeAwsLambdaListener(): void;
    /**
     * If there are no other uncaughtException listeners,
     * we want to report the exception to Honeybadger and
     * mimic the default behavior of NodeJs,
     * which is to exit the process with code 1
     *
     * Node sets up domainUncaughtExceptionClear when we use domains.
     * Since they're not set up by a user, they shouldn't affect whether we exit or not
     */
    hasOtherUncaughtExceptionListeners(): boolean;
}
//# sourceMappingURL=uncaught_exception_monitor.d.ts.map