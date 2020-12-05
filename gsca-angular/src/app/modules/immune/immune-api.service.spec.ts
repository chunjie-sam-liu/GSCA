import { TestBed } from '@angular/core/testing';

import { ImmuneApiService } from './immune-api.service';

describe('ImmuneApiService', () => {
  let service: ImmuneApiService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(ImmuneApiService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
