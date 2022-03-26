import { TestBed } from '@angular/core/testing';

import { DownloadPageApiService } from './download-page-api.service';

describe('DownloadPageService', () => {
  let service: DownloadPageApiService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(DownloadPageApiService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
