import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CnvComponent } from './cnv.component';

describe('CnvComponent', () => {
  let component: CnvComponent;
  let fixture: ComponentFixture<CnvComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ CnvComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CnvComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
