import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CnvCorComponent } from './cnv-cor.component';

describe('CnvCorComponent', () => {
  let component: CnvCorComponent;
  let fixture: ComponentFixture<CnvCorComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ CnvCorComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CnvCorComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
