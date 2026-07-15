import { CheckInDto, CheckInPayload, CheckInResponsePayload } from './types';
export declare class CheckIn implements CheckInDto {
    id?: string;
    name?: string;
    scheduleType: 'simple' | 'cron';
    slug: string;
    reportPeriod?: string;
    gracePeriod?: string;
    cronSchedule?: string;
    cronTimezone?: string;
    /**
       * Only set when the check-in has been deleted
       * after an update request.
       * Note: this property exists only locally.
       */
    private deleted;
    constructor(props: CheckInDto);
    isDeleted(): boolean;
    markAsDeleted(): void;
    validate(): void;
    asRequestPayload(): CheckInPayload;
    /**
     * Compares two check-ins, usually the one from the API and the one from the config file.
     * If the one in the config file does not match the check-in from the API,
     * then we issue an update request.
     *
     * `name`, `gracePeriod` and `cronTimezone` are optional fields that are automatically
     * set to a value from the server if one is not provided,
     * so we ignore their values if they are not set locally.
     */
    isInSync(other: CheckIn): boolean;
    static fromResponsePayload(payload: CheckInResponsePayload): CheckIn;
}
//# sourceMappingURL=check-in.d.ts.map