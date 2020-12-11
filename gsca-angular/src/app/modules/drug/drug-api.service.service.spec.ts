import { TestBed } from '@angular/core/testing';

import { DrugApi.ServiceService } from './drug-api.service.service';

describe('DrugApi.ServiceService', () => {
  let service: DrugApi.ServiceService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(DrugApi.ServiceService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
