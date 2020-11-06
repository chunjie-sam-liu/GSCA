import { TestBed } from '@angular/core/testing';

import { ExpressionApiService } from './expression-api.service';

describe('ExpressionApiService', () => {
  let service: ExpressionApiService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(ExpressionApiService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
