import { TestBed } from '@angular/core/testing';

import { DrugApiService } from './drug-api.service';

describe('DrugApiService', () => {
  let service: DrugApiService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(DrugApiService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
